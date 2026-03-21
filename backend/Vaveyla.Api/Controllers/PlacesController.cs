using Microsoft.AspNetCore.Mvc;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Vaveyla.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PlacesController : ControllerBase
{
    private static readonly HttpClient HttpClient = new HttpClient();
    private readonly string _googleApiKey;
    private readonly ILogger<PlacesController> _logger;

    public PlacesController(IConfiguration configuration, ILogger<PlacesController> logger)
    {
        _googleApiKey = configuration["GoogleMaps:ApiKey"]?.Trim() ?? string.Empty;
        _logger = logger;
    }

    [HttpGet("autocomplete")]
    public async Task<IActionResult> GetPlaceAutocomplete(
        [FromQuery] string input,
        [FromQuery] string sessiontoken,
        [FromQuery] string components = "country:tr",
        [FromQuery] string language = "tr",
        [FromQuery] string types = "address")
    {
        if (string.IsNullOrWhiteSpace(input))
        {
            return BadRequest("Input parameter is required.");
        }
        if (string.IsNullOrWhiteSpace(_googleApiKey))
        {
            return StatusCode(500, new { error = "Google Maps API key is missing." });
        }

        try
        {
            var payload = new
            {
                input,
                languageCode = language,
                sessionToken = string.IsNullOrWhiteSpace(sessiontoken) ? Guid.NewGuid().ToString() : sessiontoken,
                includedRegionCodes = new[] { "tr" }
            };
            var content = new StringContent(
                JsonSerializer.Serialize(payload),
                Encoding.UTF8,
                "application/json");
            var request = new HttpRequestMessage(
                HttpMethod.Post,
                "https://places.googleapis.com/v1/places:autocomplete");
            request.Headers.Add("X-Goog-Api-Key", _googleApiKey);
            request.Headers.Add(
                "X-Goog-FieldMask",
                "suggestions.placePrediction.placeId,suggestions.placePrediction.text.text,suggestions.placePrediction.structuredFormat.mainText.text,suggestions.placePrediction.structuredFormat.secondaryText.text");
            request.Content = content;

            var response = await HttpClient.SendAsync(request);
            var body = await response.Content.ReadAsStringAsync();

            if (response.IsSuccessStatusCode)
            {
                var transformed = TransformAutocompleteResponse(body);
                return Content(transformed, "application/json");
            }

            _logger.LogWarning("Places autocomplete failed: {Status} {Body}", response.StatusCode, body);
            return StatusCode((int)response.StatusCode, body);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Places autocomplete failed unexpectedly.");
            return StatusCode(500, new { error = ex.Message });
        }
    }

    [HttpGet("details")]
    public async Task<IActionResult> GetPlaceDetails(
        [FromQuery] string placeId,
        [FromQuery] string sessiontoken,
        [FromQuery] string language = "tr",
        [FromQuery] string fields = "address_components,formatted_address,geometry")
    {
        if (string.IsNullOrWhiteSpace(placeId))
        {
            return BadRequest("PlaceId parameter is required.");
        }
        if (string.IsNullOrWhiteSpace(_googleApiKey))
        {
            return StatusCode(500, new { error = "Google Maps API key is missing." });
        }

        try
        {
            var request = new HttpRequestMessage(
                HttpMethod.Get,
                $"https://places.googleapis.com/v1/places/{Uri.EscapeDataString(placeId)}?languageCode={Uri.EscapeDataString(language)}&sessionToken={Uri.EscapeDataString(sessiontoken ?? Guid.NewGuid().ToString())}");
            request.Headers.Add("X-Goog-Api-Key", _googleApiKey);
            request.Headers.Add(
                "X-Goog-FieldMask",
                "id,formattedAddress,addressComponents.longText,addressComponents.shortText,addressComponents.types,location.latitude,location.longitude");

            var response = await HttpClient.SendAsync(request);
            var body = await response.Content.ReadAsStringAsync();

            if (response.IsSuccessStatusCode)
            {
                var transformed = TransformDetailsResponse(body);
                return Content(transformed, "application/json");
            }

            _logger.LogWarning("Places details failed: {Status} {Body}", response.StatusCode, body);
            return StatusCode((int)response.StatusCode, body);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Places details failed unexpectedly.");
            return StatusCode(500, new { error = ex.Message });
        }
    }

    [HttpGet("test")]
    public IActionResult TestEndpoint()
    {
        return Ok(new { 
            message = "Places API Proxy is working!", 
            timestamp = DateTime.UtcNow,
            hasApiKey = !string.IsNullOrEmpty(_googleApiKey)
        });
    }

    private static string TransformAutocompleteResponse(string body)
    {
        using var document = JsonDocument.Parse(body);
        if (!document.RootElement.TryGetProperty("suggestions", out var suggestions) ||
            suggestions.ValueKind != JsonValueKind.Array)
        {
            return JsonSerializer.Serialize(new
            {
                status = "ZERO_RESULTS",
                predictions = Array.Empty<object>()
            });
        }

        var predictions = new List<object>();
        foreach (var suggestion in suggestions.EnumerateArray())
        {
            if (!suggestion.TryGetProperty("placePrediction", out var prediction))
            {
                continue;
            }

            var placeId = prediction.TryGetProperty("placeId", out var placeIdEl)
                ? placeIdEl.GetString() ?? string.Empty
                : string.Empty;
            var description = prediction.TryGetProperty("text", out var textEl) &&
                              textEl.TryGetProperty("text", out var descriptionEl)
                ? descriptionEl.GetString() ?? string.Empty
                : string.Empty;

            string mainText = string.Empty;
            string secondaryText = string.Empty;
            if (prediction.TryGetProperty("structuredFormat", out var formatEl))
            {
                if (formatEl.TryGetProperty("mainText", out var mainTextEl) &&
                    mainTextEl.TryGetProperty("text", out var mainTextValue))
                {
                    mainText = mainTextValue.GetString() ?? string.Empty;
                }
                if (formatEl.TryGetProperty("secondaryText", out var secondaryTextEl) &&
                    secondaryTextEl.TryGetProperty("text", out var secondaryTextValue))
                {
                    secondaryText = secondaryTextValue.GetString() ?? string.Empty;
                }
            }

            predictions.Add(new
            {
                description,
                place_id = placeId,
                structured_formatting = new
                {
                    main_text = mainText,
                    secondary_text = secondaryText
                }
            });
        }

        var status = predictions.Count == 0 ? "ZERO_RESULTS" : "OK";
        return JsonSerializer.Serialize(new
        {
            status,
            predictions
        });
    }

    private static string TransformDetailsResponse(string body)
    {
        using var document = JsonDocument.Parse(body);
        var root = document.RootElement;

        var formattedAddress = root.TryGetProperty("formattedAddress", out var addressEl)
            ? addressEl.GetString() ?? string.Empty
            : string.Empty;

        var components = new List<object>();
        if (root.TryGetProperty("addressComponents", out var componentsEl) &&
            componentsEl.ValueKind == JsonValueKind.Array)
        {
            foreach (var component in componentsEl.EnumerateArray())
            {
                var longName = component.TryGetProperty("longText", out var longEl)
                    ? longEl.GetString() ?? string.Empty
                    : string.Empty;
                var shortName = component.TryGetProperty("shortText", out var shortEl)
                    ? shortEl.GetString() ?? string.Empty
                    : string.Empty;

                var types = new List<string>();
                if (component.TryGetProperty("types", out var typesEl) &&
                    typesEl.ValueKind == JsonValueKind.Array)
                {
                    types.AddRange(typesEl.EnumerateArray().Select(type => type.GetString() ?? string.Empty));
                }

                components.Add(new
                {
                    long_name = longName,
                    short_name = shortName,
                    types
                });
            }
        }

        double lat = 0;
        double lng = 0;
        if (root.TryGetProperty("location", out var locationEl))
        {
            if (locationEl.TryGetProperty("latitude", out var latEl) &&
                latEl.TryGetDouble(out var latitude))
            {
                lat = latitude;
            }
            if (locationEl.TryGetProperty("longitude", out var lngEl) &&
                lngEl.TryGetDouble(out var longitude))
            {
                lng = longitude;
            }
        }

        return JsonSerializer.Serialize(new
        {
            status = "OK",
            result = new
            {
                formatted_address = formattedAddress,
                address_components = components,
                geometry = new
                {
                    location = new
                    {
                        lat,
                        lng
                    }
                }
            }
        });
    }
}