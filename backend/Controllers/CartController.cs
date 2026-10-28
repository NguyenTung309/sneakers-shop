using System.Security.Claims;
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
    [Authorize]
    public class CartController : ControllerBase
    {
        private readonly SneakersContext _context;

        public CartController(SneakersContext context)
        {
            _context = context;
        }

        private int GetUserId() => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));

        [HttpGet]
        public async Task<ActionResult<IEnumerable<CartItemDto>>> GetCartItems()
        {
            var userId = GetUserId();
            var items = await _context.CartItems
                .Include(x => x.Shoe)
                .Include(x => x.ProductVariant)
                .Where(x => x.UserId == userId)
                .ToListAsync();

            var result = items.Select(i => new CartItemDto
            {
                Id = i.Id,
                Shoe = new ShoeDto
                {
                    Id = i.Shoe.Id,
                    Name = i.Shoe.Name,
                    Brand = i.Shoe.Brand,
                    Price = i.Shoe.Price,
                    ImageUrl = i.Shoe.ImageUrl
                },
                Variant = new ProductVariantDto
                {
                    Id = i.ProductVariant.Id,
                    Size = i.ProductVariant.Size,
                    Color = i.ProductVariant.Color
                },
                Quantity = i.Quantity
            }).ToList();

            return Ok(result);
        }

        [HttpPost]
        public async Task<ActionResult> AddCartItem([FromBody] AddToCartDto model)
        {
            var userId = GetUserId();
            if (model.Quantity <= 0)
            {
                return BadRequest("Quantity must be greater than zero");
            }

            var variant = await _context.ProductVariants
                .SingleOrDefaultAsync(x => x.Id == model.ProductVariantId && x.ShoeId == model.ShoeId);
            if (variant == null)
            {
                return BadRequest("Invalid product variant");
            }

            var existing = await _context.CartItems
                .SingleOrDefaultAsync(x => x.UserId == userId && x.ShoeId == model.ShoeId && x.ProductVariantId == model.ProductVariantId);

            var requestedQuantity = model.Quantity + (existing?.Quantity ?? 0);
            if (requestedQuantity > variant.Stock)
            {
                return BadRequest($"Only {variant.Stock} item(s) left in stock");
            }

            if (existing != null)
            {
                existing.Quantity += model.Quantity;
            }
            else
            {
                _context.CartItems.Add(new CartItem
                {
                    UserId = userId,
                    ShoeId = model.ShoeId,
                    ProductVariantId = model.ProductVariantId,
                    Quantity = model.Quantity
                });
            }

            await _context.SaveChangesAsync();
            return Ok();
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> RemoveCartItem(int id)
        {
            var userId = GetUserId();
            var item = await _context.CartItems.SingleOrDefaultAsync(x => x.Id == id && x.UserId == userId);
            if (item == null) return NotFound();

            _context.CartItems.Remove(item);
            await _context.SaveChangesAsync();
            return NoContent();
        }
    }
}
