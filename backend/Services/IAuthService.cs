using SneakersShopBackend.Dtos;
using SneakersShopBackend.Models;

namespace SneakersShopBackend.Services
{
    public interface IAuthService
    {
        Task<AuthResponseDto> RegisterAsync(RegisterDto model);
        Task<AuthResponseDto> LoginAsync(LoginDto model);
    }
}