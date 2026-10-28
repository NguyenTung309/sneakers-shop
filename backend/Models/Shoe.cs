namespace SneakersShopBackend.Models
{
    public class Shoe
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string Brand { get; set; }
        public string Description { get; set; }
        public decimal Price { get; set; }
        public string ImageUrl { get; set; }
        public ICollection<ProductVariant> ProductVariants { get; set; }
        public ICollection<Review> Reviews { get; set; }
    }
}