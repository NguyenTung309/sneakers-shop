using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SneakersShopBackend.Data;
using SneakersShopBackend.Dtos;
using SneakersShopBackend.Models;

namespace SneakersShopBackend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ProductsController : ControllerBase
    {
        private readonly SneakersContext _context;

        public ProductsController(SneakersContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetProducts([FromQuery] SearchShoesDto search)
        {
            var query = _context.Shoes
                .Include(s => s.ProductVariants)
                .Include(s => s.Reviews)
                .ThenInclude(r => r.User)
                .AsQueryable();

            if (!string.IsNullOrEmpty(search.Name))
                query = query.Where(s => s.Name.Contains(search.Name));
            if (!string.IsNullOrEmpty(search.Brand))
                query = query.Where(s => s.Brand.Contains(search.Brand));
            if (!string.IsNullOrEmpty(search.Size))
                query = query.Where(s => s.ProductVariants.Any(pv => pv.Size == search.Size));
            if (search.MinPrice.HasValue)
                query = query.Where(s => s.Price >= search.MinPrice.Value);
            if (search.MaxPrice.HasValue)
                query = query.Where(s => s.Price <= search.MaxPrice.Value);

            var shoes = await query.ToListAsync();
            var result = shoes.Select(s => MapToDto(s)).ToList();

            return Ok(result);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetProduct(int id)
        {
            var shoe = await _context.Shoes
                .Include(s => s.ProductVariants)
                .Include(s => s.Reviews).ThenInclude(r => r.User)
                .FirstOrDefaultAsync(s => s.Id == id);

            if (shoe == null) return NotFound();

            return Ok(MapToDto(shoe));
        }

        [Authorize(Roles = "Admin")]
        [HttpPost]
        public async Task<IActionResult> CreateProduct([FromBody] CreateShoeDto model)
        {
            var shoe = new Shoe
            {
                Name = model.Name,
                Brand = model.Brand,
                Description = model.Description,
                Price = model.Price,
                ImageUrl = model.ImageUrl
            };

            _context.Shoes.Add(shoe);
            await _context.SaveChangesAsync();

            if (model.Variants != null)
            {
                foreach (var v in model.Variants)
                {
                    _context.ProductVariants.Add(new ProductVariant
                    {
                        ShoeId = shoe.Id,
                        Size = v.Size,
                        Color = v.Color,
                        Stock = v.Stock
                    });
                }
                await _context.SaveChangesAsync();
            }

            return CreatedAtAction(nameof(GetProduct), new { id = shoe.Id }, shoe);
        }

        [Authorize(Roles = "Admin")]
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateProduct(int id, [FromBody] CreateShoeDto model)
        {
            var shoe = await _context.Shoes.FindAsync(id);
            if (shoe == null) return NotFound();

            shoe.Name = model.Name;
            shoe.Brand = model.Brand;
            shoe.Description = model.Description;
            shoe.Price = model.Price;
            shoe.ImageUrl = model.ImageUrl;

            var oldVariants = _context.ProductVariants.Where(pv => pv.ShoeId == id);
            _context.ProductVariants.RemoveRange(oldVariants);

            if (model.Variants != null)
            {
                foreach (var v in model.Variants)
                {
                    _context.ProductVariants.Add(new ProductVariant
                    {
                        ShoeId = shoe.Id,
                        Size = v.Size,
                        Color = v.Color,
                        Stock = v.Stock
                    });
                }
            }

            await _context.SaveChangesAsync();
            return NoContent();
        }

        // FIX: Thêm DELETE endpoint bị thiếu
        [Authorize(Roles = "Admin")]
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteProduct(int id)
        {
            var shoe = await _context.Shoes.FindAsync(id);
            if (shoe == null) return NotFound();

            // Kiểm tra xem sản phẩm có đang nằm trong OrderItem không
            var hasOrders = await _context.OrderItems.AnyAsync(oi => oi.ShoeId == id);
            if (hasOrders)
            {
                return BadRequest("Cannot delete product that has existing orders.");
            }

            _context.Shoes.Remove(shoe);
            await _context.SaveChangesAsync();
            return NoContent();
        }

        [Authorize]
        [HttpPost("{id}/review")]
        public async Task<IActionResult> AddReview(int id, [FromBody] AddReviewDto model)
        {
            var userId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);

            var shoeExists = await _context.Shoes.AnyAsync(s => s.Id == id);
            if (!shoeExists) return NotFound("Product not found");

            var review = new Review
            {
                ShoeId = id,   // FIX: lấy từ route, không lấy từ body nữa
                UserId = userId,
                Rating = model.Rating,
                Comment = model.Comment ?? string.Empty
            };

            _context.Reviews.Add(review);
            await _context.SaveChangesAsync();

            return Ok();
        }

        // ── Helper ────────────────────────────────────────────────────────────
        private static ShoeDto MapToDto(Shoe s) => new()
        {
            Id = s.Id,
            Name = s.Name,
            Brand = s.Brand,
            Description = s.Description,
            Price = s.Price,
            ImageUrl = s.ImageUrl,
            Variants = s.ProductVariants?.Select(pv => new ProductVariantDto
            {
                Id = pv.Id,
                Size = pv.Size,
                Color = pv.Color,
                Stock = pv.Stock
            }).ToList() ?? new(),
            Reviews = s.Reviews?.Select(r => new ReviewDto
            {
                Id = r.Id,
                Rating = r.Rating,
                Comment = r.Comment,
                UserName = r.User.FullName,
                CreatedAt = r.CreatedAt
            }).ToList() ?? new()
        };
    }
}