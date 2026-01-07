using ExampleApi.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddScoped<ICalculatorService, CalculatorService>();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.MapGet("/health", () => new
{
    Status = "healthy",
    Timestamp = DateTime.UtcNow,
    Version = "1.0.0"
});

app.MapPost("/api/calculator/total", (CalculateRequest request, ICalculatorService calculator) =>
{
    try
    {
        var result = calculator.CalculateTotal(request.Items, request.TaxRate, request.DiscountPercent);
        return Results.Ok(result);
    }
    catch (ArgumentException ex)
    {
        return Results.BadRequest(new { Error = ex.Message });
    }
});

app.Run();

/// <summary>
/// Request model for total calculation.
/// </summary>
/// <param name="Items">Cart items to calculate.</param>
/// <param name="TaxRate">Tax rate as decimal.</param>
/// <param name="DiscountPercent">Optional discount percentage.</param>
public record CalculateRequest(CartItem[] Items, decimal TaxRate, decimal DiscountPercent = 0);
