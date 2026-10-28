namespace SneakersShopBackend.Models
{
    public class Review
    {
        public int Id { get; set; }
        public int ShoeId { get; set; }
        public Shoe Shoe { get; set; }
        public int UserId { get; set; }
        public User User { get; set; }
        public int Rating { get; set; } // 1-5
        public string Comment { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
    }
}