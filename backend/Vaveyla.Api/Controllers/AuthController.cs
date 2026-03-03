using Microsoft.AspNetCore.Mvc;
using Vaveyla.Api.Data;
using Vaveyla.Api.Models;

namespace Vaveyla.Api.Controllers;

[ApiController]
[Route("api/auth")]
public sealed class AuthController : ControllerBase
{
    private readonly IUserRepository _users;

    public AuthController(IUserRepository users)
    {
        _users = users;
    }

    [HttpPost("register")]
    public async Task<ActionResult<AuthResponse>> Register(
        [FromBody] RegisterRequest request,
        CancellationToken cancellationToken)
    {
        if (!request.IsPrivacyPolicyAccepted || !request.IsTermsOfServiceAccepted)
        {
            return BadRequest(new { message = "Privacy policy and terms consent are required." });
        }

        if (!TryValidatePassword(request.Password, out var passwordValidationError))
        {
            return BadRequest(new { message = passwordValidationError });
        }

        var email = request.Email.Trim().ToLowerInvariant();
        var existing = await _users.GetByEmailAsync(email, cancellationToken);
        if (existing is not null)
        {
            return Conflict(new { message = "Email already registered." });
        }

        var user = new User
        {
            UserId = Guid.NewGuid(),
            FullName = request.FullName.Trim(),
            Email = email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Role = (UserRole)request.RoleId,
            IsPrivacyPolicyAccepted = request.IsPrivacyPolicyAccepted,
            IsTermsOfServiceAccepted = request.IsTermsOfServiceAccepted,
            CreatedAtUtc = DateTime.UtcNow,
        };

        await _users.CreateAsync(user, cancellationToken);

        return Ok(new AuthResponse
        {
            UserId = user.UserId,
            Role = user.Role,
            FullName = user.FullName,
        });
    }

    private static bool TryValidatePassword(string password, out string? errorMessage)
    {
        if (string.IsNullOrWhiteSpace(password) || password.Length < 6)
        {
            errorMessage = "Password must be at least 6 characters long.";
            return false;
        }

        if (!password.Any(char.IsUpper))
        {
            errorMessage = "Password must contain at least one uppercase letter.";
            return false;
        }

        if (!password.Any(char.IsLower))
        {
            errorMessage = "Password must contain at least one lowercase letter.";
            return false;
        }

        if (!password.Any(char.IsDigit))
        {
            errorMessage = "Password must contain at least one number.";
            return false;
        }

        if (!password.Any(c => !char.IsLetterOrDigit(c)))
        {
            errorMessage = "Password must contain at least one special character.";
            return false;
        }

        errorMessage = null;
        return true;
    }

    [HttpPost("login")]
    public async Task<ActionResult<AuthResponse>> Login(
        [FromBody] LoginRequest request,
        CancellationToken cancellationToken)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var user = await _users.GetByEmailAsync(email, cancellationToken);
        if (user is null)
        {
            return Unauthorized(new { message = "Invalid credentials." });
        }

        var validPassword = BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash);
        if (!validPassword)
        {
            return Unauthorized(new { message = "Invalid credentials." });
        }

        return Ok(new AuthResponse
        {
            UserId = user.UserId,
            Role = user.Role,
            FullName = user.FullName,
        });
    }
}
