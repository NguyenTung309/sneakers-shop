using System.ComponentModel.DataAnnotations;

namespace SneakersShopBackend.Dtos
{
    public class RegisterDto
    {
        [Required]
        public string Email { get; set; }
        [Required]
        public string Password { get; set; }
        [Required]
        public string FullName { get; set; }
    }

    public class LoginDto
    {
        [Required]
        public string Email { get; set; }
        [Required]
        public string Password { get; set; }
    }

    public class AuthResponseDto
    {
        public string Email { get; set; }
        public string FullName { get; set; }
        public string Token { get; set; }
        public string Role { get; set; }
    }

    public class ShoeDto
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string Brand { get; set; }
        public string Description { get; set; }
        public decimal Price { get; set; }
        public string ImageUrl { get; set; }
        public List<ProductVariantDto> Variants { get; set; }
        public List<ReviewDto> Reviews { get; set; }
    }

    public class ProductVariantDto
    {
        public int Id { get; set; }
        public string Size { get; set; }
        public string Color { get; set; }
        public int Stock { get; set; }
    }

    public class ReviewDto
    {
        public int Id { get; set; }
        public int Rating { get; set; }
        public string Comment { get; set; }
        public string UserName { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class AddToCartDto
    {
        [Required]
        public int ShoeId { get; set; }
        [Required]
        public int ProductVariantId { get; set; }
        [Required]
        public int Quantity { get; set; }
    }

    public class CartItemDto
    {
        public int Id { get; set; }
        public ShoeDto Shoe { get; set; }
        public ProductVariantDto Variant { get; set; }
        public int Quantity { get; set; }
    }

    public class OrderDto
    {
        public int Id { get; set; }
        public DateTime OrderDate { get; set; }
        public string Status { get; set; }
        public decimal TotalAmount { get; set; }
        public List<OrderItemDto> Items { get; set; }
    }

    public class OrderItemDto
    {
        public int Id { get; set; }
        public ShoeDto Shoe { get; set; }
        public ProductVariantDto Variant { get; set; }
        public int Quantity { get; set; }
        public decimal Price { get; set; }
    }

    public class CreateOrderDto
    {
        public List<AddToCartDto> Items { get; set; }
    }

    public class UpdateOrderStatusDto
    {
        [Required]
        public string Status { get; set; }
    }

    public class CreateShoeDto
    {
        [Required]
        public string Name { get; set; }
        [Required]
        public string Brand { get; set; }
        [Required]
        public string Description { get; set; }
        [Required]
        public decimal Price { get; set; }
        [Required]
        public string ImageUrl { get; set; }
        public List<ProductVariantDto> Variants { get; set; }
    }

    // ShoeId bỏ ra vì đã có {id} trong route path rồi
    public class AddReviewDto
    {
        [Required]
        [Range(1, 5, ErrorMessage = "Rating must be between 1 and 5")]
        public int Rating { get; set; }
        public string Comment { get; set; }
    }

    public class SearchShoesDto
    {
        public string? Name { get; set; }
        public string? Brand { get; set; }
        public string? Size { get; set; }
        public decimal? MinPrice { get; set; }
        public decimal? MaxPrice { get; set; }
    }
}