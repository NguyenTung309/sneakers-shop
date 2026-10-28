using Microsoft.EntityFrameworkCore;
using SneakersShopBackend.Models;

namespace SneakersShopBackend.Data
{
    public class SneakersContext : DbContext
    {
        public SneakersContext(DbContextOptions<SneakersContext> options) : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<Shoe> Shoes { get; set; }
        public DbSet<CartItem> CartItems { get; set; }
        public DbSet<ProductVariant> ProductVariants { get; set; }
        public DbSet<Review> Reviews { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderItem> OrderItems { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // Configure relationships
            modelBuilder.Entity<ProductVariant>()
                .HasOne(pv => pv.Shoe)
                .WithMany(s => s.ProductVariants)
                .HasForeignKey(pv => pv.ShoeId);

            modelBuilder.Entity<Review>()
                .HasOne(r => r.Shoe)
                .WithMany(s => s.Reviews)
                .HasForeignKey(r => r.ShoeId);

            modelBuilder.Entity<Review>()
                .HasOne(r => r.User)
                .WithMany()
                .HasForeignKey(r => r.UserId);

            modelBuilder.Entity<Order>()
                .HasOne(o => o.User)
                .WithMany()
                .HasForeignKey(o => o.UserId);

            modelBuilder.Entity<OrderItem>()
                .HasOne(oi => oi.Order)
                .WithMany(o => o.OrderItems)
                .HasForeignKey(oi => oi.OrderId);

            modelBuilder.Entity<OrderItem>()
                .HasOne(oi => oi.Shoe)
                .WithMany()
                .HasForeignKey(oi => oi.ShoeId);

            modelBuilder.Entity<OrderItem>()
                .HasOne(oi => oi.ProductVariant)
                .WithMany()
                .HasForeignKey(oi => oi.ProductVariantId);
        }
    }
}