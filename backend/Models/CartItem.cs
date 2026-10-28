namespace SneakersShopBackend.Models
{
    public class CartItem
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int ShoeId { get; set; }
        public int ProductVariantId { get; set; }
        public int Quantity { get; set; }

        public User User { get; set; }
        public Shoe Shoe { get; set; }
        public ProductVariant ProductVariant { get; set; }
    }
}