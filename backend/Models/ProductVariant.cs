namespace SneakersShopBackend.Models
{
    public class ProductVariant
    {
        public int Id { get; set; }
        public int ShoeId { get; set; }
        public Shoe Shoe { get; set; }
        public string Size { get; set; }
        public string Color { get; set; }
        public int Stock { get; set; }
    }
}