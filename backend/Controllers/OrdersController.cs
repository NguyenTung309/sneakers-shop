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
    public class OrdersController : ControllerBase
    {
        private readonly SneakersContext _context;

        public OrdersController(SneakersContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetMyOrders()
        {
            var userId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);

            var orders = await _context.Orders.Include(o => o.OrderItems).ThenInclude(oi => oi.Shoe)
                .Include(o => o.OrderItems).ThenInclude(oi => oi.ProductVariant)
                .Where(o => o.UserId == userId).ToListAsync();

            var result = orders.Select(o => new OrderDto
            {
                Id = o.Id,
                OrderDate = o.OrderDate,
                Status = o.Status,
                TotalAmount = o.TotalAmount,
                Items = o.OrderItems.Select(oi => new OrderItemDto
                {
                    Id = oi.Id,
                    Shoe = new ShoeDto { Id = oi.Shoe.Id, Name = oi.Shoe.Name, Brand = oi.Shoe.Brand, Price = oi.Shoe.Price, ImageUrl = oi.Shoe.ImageUrl },
                    Variant = new ProductVariantDto { Id = oi.ProductVariant.Id, Size = oi.ProductVariant.Size, Color = oi.ProductVariant.Color },
                    Quantity = oi.Quantity,
                    Price = oi.Price
                }).ToList()
            }).ToList();

            return Ok(result);
        }

        [HttpPost]
        public async Task<IActionResult> CreateOrder([FromBody] CreateOrderDto model)
        {
            var userId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            if (model.Items == null || !model.Items.Any())
            {
                return BadRequest("Order must contain at least one item");
            }

            var resolvedItems = new List<(AddToCartDto Request, Shoe Shoe, ProductVariant Variant)>();
            foreach (var item in model.Items)
            {
                if (item.Quantity <= 0)
                {
                    return BadRequest("Quantity must be greater than zero");
                }

                var shoe = await _context.Shoes.FindAsync(item.ShoeId);
                var variant = await _context.ProductVariants
                    .SingleOrDefaultAsync(v => v.Id == item.ProductVariantId && v.ShoeId == item.ShoeId);
                if (shoe == null || variant == null)
                {
                    return BadRequest("Invalid product or variant");
                }
                if (variant.Stock < item.Quantity)
                {
                    return BadRequest($"Not enough stock for {shoe.Name} ({variant.Size} - {variant.Color})");
                }

                resolvedItems.Add((item, shoe, variant));
            }

            var order = new Order
            {
                UserId = userId,
                TotalAmount = 0
            };

            _context.Orders.Add(order);
            await _context.SaveChangesAsync();

            decimal total = 0;
            foreach (var resolved in resolvedItems)
            {
                var item = resolved.Request;
                var shoe = resolved.Shoe;
                var variant = resolved.Variant;

                var orderItem = new OrderItem
                {
                    OrderId = order.Id,
                    ShoeId = item.ShoeId,
                    ProductVariantId = item.ProductVariantId,
                    Quantity = item.Quantity,
                    Price = shoe.Price
                };

                _context.OrderItems.Add(orderItem);
                total += shoe.Price * item.Quantity;
                variant.Stock -= item.Quantity;

                // Remove from cart
                var cartItem = await _context.CartItems.FirstOrDefaultAsync(ci => ci.UserId == userId && ci.ShoeId == item.ShoeId && ci.ProductVariantId == item.ProductVariantId);
                if (cartItem != null)
                {
                    _context.CartItems.Remove(cartItem);
                }
            }

            order.TotalAmount = total;
            await _context.SaveChangesAsync();

            return Ok(order.Id);
        }

        [Authorize(Roles = "Admin")]
        [HttpGet("all")]
        public async Task<IActionResult> GetAllOrders()
        {
            var orders = await _context.Orders.Include(o => o.OrderItems).ThenInclude(oi => oi.Shoe)
                .Include(o => o.OrderItems).ThenInclude(oi => oi.ProductVariant)
                .Include(o => o.User).ToListAsync();

            var result = orders.Select(o => new OrderDto
            {
                Id = o.Id,
                OrderDate = o.OrderDate,
                Status = o.Status,
                TotalAmount = o.TotalAmount,
                Items = o.OrderItems.Select(oi => new OrderItemDto
                {
                    Id = oi.Id,
                    Shoe = new ShoeDto { Id = oi.Shoe.Id, Name = oi.Shoe.Name, Brand = oi.Shoe.Brand, Price = oi.Shoe.Price, ImageUrl = oi.Shoe.ImageUrl },
                    Variant = new ProductVariantDto { Id = oi.ProductVariant.Id, Size = oi.ProductVariant.Size, Color = oi.ProductVariant.Color },
                    Quantity = oi.Quantity,
                    Price = oi.Price
                }).ToList()
            }).ToList();

            return Ok(result);
        }

        [Authorize(Roles = "Admin")]
        [HttpPut("{id}/status")]
        public async Task<IActionResult> UpdateOrderStatus(int id, [FromBody] UpdateOrderStatusDto model)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();

            var transitions = new Dictionary<string, string>
            {
                ["Pending"] = "Confirmed",
                ["Confirmed"] = "Preparing",
                ["Preparing"] = "Shipping",
                ["Shipping"] = "Completed"
            };

            if (!transitions.TryGetValue(order.Status, out var nextStatus))
            {
                return BadRequest("This order can no longer be updated");
            }

            if (!string.Equals(model.Status, nextStatus, StringComparison.OrdinalIgnoreCase))
            {
                return BadRequest($"Invalid status transition. Next status must be '{nextStatus}'.");
            }

            order.Status = model.Status;
            await _context.SaveChangesAsync();

            return NoContent();
        }
    }
}
