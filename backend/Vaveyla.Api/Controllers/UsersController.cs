using Microsoft.AspNetCore.Mvc;
using Vaveyla.Api.Data;
using Vaveyla.Api.Models;

namespace Vaveyla.Api.Controllers;

[ApiController]
[Route("api/users")]
public sealed class UsersController : ControllerBase
{
    private readonly IUserRepository _users;
    private readonly IWebHostEnvironment _environment;

    public UsersController(IUserRepository users, IWebHostEnvironment environment)
    {
        _users = users;
        _environment = environment;
    }

    [HttpGet("{userId:guid}/profile")]
    public async Task<ActionResult<UserProfileDto>> GetProfile(
        [FromRoute] Guid userId,
        CancellationToken cancellationToken)
    {
        if (userId == Guid.Empty)
        {
            return BadRequest(new { message = "User id is required." });
        }

        var user = await _users.GetByIdAsync(userId, cancellationToken);
        if (user is null)
        {
            return NotFound(new { message = "User not found." });
        }

        return Ok(MapProfile(user));
    }

    [HttpPost("{userId:guid}/profile-photo")]
    public async Task<ActionResult<UserProfileDto>> UploadProfilePhoto(
        [FromRoute] Guid userId,
        [FromForm] IFormFile file,
        CancellationToken cancellationToken)
    {
        if (userId == Guid.Empty)
        {
            return BadRequest(new { message = "User id is required." });
        }

        if (file.Length == 0)
        {
            return BadRequest(new { message = "File is required." });
        }

        var user = await _users.GetByIdAsync(userId, cancellationToken);
        if (user is null)
        {
            return NotFound(new { message = "User not found." });
        }

        var relativePath = await SaveUploadAsync(userId, file, cancellationToken);
        user.ProfilePhotoPath = relativePath;
        await _users.UpdateAsync(user, cancellationToken);
        return Ok(MapProfile(user));
    }

    [HttpGet("{userId:guid}/addresses")]
    public async Task<ActionResult<List<UserAddressDto>>> GetAddresses(
        [FromRoute] Guid userId,
        CancellationToken cancellationToken)
    {
        if (userId == Guid.Empty)
        {
            return BadRequest(new { message = "User id is required." });
        }

        var user = await _users.GetByIdAsync(userId, cancellationToken);
        if (user is null)
        {
            return NotFound(new { message = "User not found." });
        }

        var addresses = await _users.GetAddressesAsync(userId, cancellationToken);
        return Ok(addresses.Select(MapAddress).ToList());
    }

    [HttpPost("{userId:guid}/addresses")]
    public async Task<ActionResult<UserAddressDto>> CreateAddress(
        [FromRoute] Guid userId,
        [FromBody] CreateUserAddressRequest request,
        CancellationToken cancellationToken)
    {
        if (userId == Guid.Empty)
        {
            return BadRequest(new { message = "User id is required." });
        }

        var user = await _users.GetByIdAsync(userId, cancellationToken);
        if (user is null)
        {
            return NotFound(new { message = "User not found." });
        }

        var addresses = await _users.GetAddressesAsync(userId, cancellationToken);
        var shouldSelect = request.IsSelected || addresses.Count == 0;
        if (shouldSelect)
        {
            await ClearAddressSelectionAsync(userId, null, cancellationToken);
        }

        var address = new UserAddress
        {
            AddressId = Guid.NewGuid(),
            UserId = userId,
            Label = request.Label.Trim(),
            AddressLine = request.AddressLine.Trim(),
            AddressDetail = string.IsNullOrWhiteSpace(request.AddressDetail)
                ? null
                : request.AddressDetail.Trim(),
            IsSelected = shouldSelect
        };

        var created = await _users.AddAddressAsync(address, cancellationToken);
        return Ok(MapAddress(created));
    }

    [HttpPut("{userId:guid}/addresses/{addressId:guid}")]
    public async Task<ActionResult<UserAddressDto>> UpdateAddress(
        [FromRoute] Guid userId,
        [FromRoute] Guid addressId,
        [FromBody] UpdateUserAddressRequest request,
        CancellationToken cancellationToken)
    {
        if (userId == Guid.Empty || addressId == Guid.Empty)
        {
            return BadRequest(new { message = "User id and address id are required." });
        }

        var address = await _users.GetAddressByIdAsync(userId, addressId, cancellationToken);
        if (address is null)
        {
            return NotFound(new { message = "Address not found." });
        }

        if (request.IsSelected)
        {
            await ClearAddressSelectionAsync(userId, addressId, cancellationToken);
        }
        else if (address.IsSelected)
        {
            var allAddresses = await _users.GetAddressesAsync(userId, cancellationToken);
            var fallback = allAddresses.FirstOrDefault(x => x.AddressId != addressId);
            if (fallback is not null)
            {
                fallback.IsSelected = true;
            }
        }

        address.Label = request.Label.Trim();
        address.AddressLine = request.AddressLine.Trim();
        address.AddressDetail = string.IsNullOrWhiteSpace(request.AddressDetail)
            ? null
            : request.AddressDetail.Trim();
        address.IsSelected = request.IsSelected;

        await _users.SaveChangesAsync(cancellationToken);
        return Ok(MapAddress(address));
    }

    [HttpDelete("{userId:guid}/addresses/{addressId:guid}")]
    public async Task<IActionResult> DeleteAddress(
        [FromRoute] Guid userId,
        [FromRoute] Guid addressId,
        CancellationToken cancellationToken)
    {
        if (userId == Guid.Empty || addressId == Guid.Empty)
        {
            return BadRequest(new { message = "User id and address id are required." });
        }

        var address = await _users.GetAddressByIdAsync(userId, addressId, cancellationToken);
        if (address is null)
        {
            return NotFound(new { message = "Address not found." });
        }

        var wasSelected = address.IsSelected;
        await _users.DeleteAddressAsync(address, cancellationToken);

        if (wasSelected)
        {
            var remaining = await _users.GetAddressesAsync(userId, cancellationToken);
            var fallback = remaining.FirstOrDefault();
            if (fallback is not null)
            {
                fallback.IsSelected = true;
                await _users.SaveChangesAsync(cancellationToken);
            }
        }

        return NoContent();
    }

    private UserProfileDto MapProfile(User user)
    {
        return new UserProfileDto(
            user.UserId,
            user.FullName,
            user.Email,
            BuildPublicUrl(user.ProfilePhotoPath));
    }

    private UserAddressDto MapAddress(UserAddress address)
    {
        return new UserAddressDto(
            address.AddressId,
            address.Label,
            address.AddressLine,
            address.AddressDetail,
            address.IsSelected,
            address.CreatedAtUtc);
    }

    private string? BuildPublicUrl(string? relativePath)
    {
        if (string.IsNullOrWhiteSpace(relativePath))
        {
            return null;
        }

        return $"{Request.Scheme}://{Request.Host}/{relativePath}";
    }

    private async Task<string> SaveUploadAsync(
        Guid userId,
        IFormFile file,
        CancellationToken cancellationToken)
    {
        var extension = Path.GetExtension(file.FileName);
        var fileName = $"{Guid.NewGuid():N}{extension}";
        var relativePath = Path.Combine("uploads", "users", userId.ToString(), "profile", fileName);
        var webRootPath = _environment.WebRootPath;
        if (string.IsNullOrWhiteSpace(webRootPath))
        {
            webRootPath = Path.Combine(_environment.ContentRootPath, "wwwroot");
        }
        if (!Directory.Exists(webRootPath))
        {
            Directory.CreateDirectory(webRootPath);
        }

        var absolutePath = Path.Combine(webRootPath, relativePath);
        var directory = Path.GetDirectoryName(absolutePath);
        if (!string.IsNullOrWhiteSpace(directory))
        {
            Directory.CreateDirectory(directory);
        }

        await using var stream = System.IO.File.Create(absolutePath);
        await file.CopyToAsync(stream, cancellationToken);
        return relativePath.Replace(Path.DirectorySeparatorChar, '/');
    }

    private async Task ClearAddressSelectionAsync(
        Guid userId,
        Guid? exceptAddressId,
        CancellationToken cancellationToken)
    {
        var addresses = await _users.GetAddressesAsync(userId, cancellationToken);
        foreach (var existing in addresses)
        {
            if (exceptAddressId.HasValue && existing.AddressId == exceptAddressId.Value)
            {
                continue;
            }

            if (existing.IsSelected)
            {
                existing.IsSelected = false;
            }
        }

        await _users.SaveChangesAsync(cancellationToken);
    }
}
