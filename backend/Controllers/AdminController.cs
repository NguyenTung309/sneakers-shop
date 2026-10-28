using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SneakersShopBackend.Data;

namespace SneakersShopBackend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "Admin")]
    public class AdminController : ControllerBase
    {
        private readonly SneakersContext _context;

        public AdminController(SneakersContext context)
        {
            _context = context;
        }

        [HttpGet("stats")]
        public async Task<IActionResult> GetStats()
        {
            var totalRevenue = await _context.Orders.Where(o => o.Status == "Completed").SumAsync(o => o.TotalAmount);
            var totalOrders = await _context.Orders.CountAsync();
            var totalUsers = await _context.Users.CountAsync();
            var totalProducts = await _context.Shoes.CountAsync();

            var bestSelling = await _context.OrderItems
                .GroupBy(oi => oi.ShoeId)
                .Select(g => new
                {
                    ShoeId = g.Key,
                    TotalSold = g.Sum(oi => oi.Quantity)
                })
                .OrderByDescending(x => x.TotalSold)
                .Take(5)
                .Join(_context.Shoes, x => x.ShoeId, s => s.Id, (x, s) => new
                {
                    s.Name,
                    s.Brand,
                    TotalSold = x.TotalSold
                })
                .ToListAsync();

            return Ok(new
            {
                TotalRevenue = totalRevenue,
                TotalOrders = totalOrders,
                TotalUsers = totalUsers,
                TotalProducts = totalProducts,
                BestSellingProducts = bestSelling
            });
        }
    }
}