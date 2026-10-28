using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using SneakersShopBackend.Data;
using SneakersShopBackend.Dtos;
using SneakersShopBackend.Models;

namespace SneakersShopBackend.Services
{
    public class AuthService : IAuthService
    {
        private readonly SneakersContext _context;
        private readonly JwtSettings _jwtSettings;

        public AuthService(SneakersContext context, IOptions<JwtSettings> jwtSettings)
        {
            _context = context;
            _jwtSettings = jwtSettings.Value;
        }

        public async Task<AuthResponseDto> RegisterAsync(RegisterDto model)
        {
            var existing = await _context.Users.SingleOrDefaultAsync(u => u.Email == model.Email);
            if (existing != null)
            {
                throw new InvalidOperationException("Email da ton tai");
            }

            var user = new User
            {
                Email = model.Email,
                FullName = model.FullName,
                Password = BCrypt.Net.BCrypt.HashPassword(model.Password),
                Role = "User"
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            return BuildAuthResponse(user);
        }

        public async Task<AuthResponseDto> LoginAsync(LoginDto model)
        {
            var user = await _context.Users.SingleOrDefaultAsync(u => u.Email == model.Email);
            if (user == null || !await VerifyPasswordAsync(user, model.Password))
            {
                throw new InvalidOperationException("Email hoac mat khau khong dung");
            }

            return BuildAuthResponse(user);
        }

        private async Task<bool> VerifyPasswordAsync(User user, string inputPassword)
        {
            if (string.IsNullOrWhiteSpace(user.Password))
            {
                return false;
            }

            if (user.Password.StartsWith("$2"))
            {
                return BCrypt.Net.BCrypt.Verify(inputPassword, user.Password);
            }

            if (!string.Equals(user.Password, inputPassword, StringComparison.Ordinal))
            {
                return false;
            }

            // Upgrade old dev/db-first plain-text seed passwords to BCrypt after first successful login.
            user.Password = BCrypt.Net.BCrypt.HashPassword(inputPassword);
            await _context.SaveChangesAsync();
            return true;
        }

        private AuthResponseDto BuildAuthResponse(User user)
        {
            return new AuthResponseDto
            {
                Email = user.Email,
                FullName = user.FullName,
                Token = CreateToken(user),
                Role = user.Role
            };
        }

        private string CreateToken(User user)
        {
            var claims = new List<Claim>
            {
                new(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new(ClaimTypes.Email, user.Email),
                new(ClaimTypes.Name, user.FullName ?? user.Email),
                new(ClaimTypes.Role, user.Role)
            };

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwtSettings.Key));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
            var expires = DateTime.UtcNow.AddMinutes(_jwtSettings.DurationInMinutes);

            var token = new JwtSecurityToken(
                issuer: _jwtSettings.Issuer,
                audience: _jwtSettings.Audience,
                claims: claims,
                expires: expires,
                signingCredentials: creds);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}
