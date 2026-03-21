using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Vaveyla.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddCustomerOrders : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "CustomerOrders",
                columns: table => new
                {
                    OrderId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerUserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    RestaurantId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Items = table.Column<string>(type: "nvarchar(800)", maxLength: 800, nullable: false),
                    Total = table.Column<int>(type: "int", nullable: false),
                    DeliveryAddress = table.Column<string>(type: "nvarchar(400)", maxLength: 400, nullable: false),
                    DeliveryAddressDetail = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    CustomerLat = table.Column<double>(type: "float", nullable: true),
                    CustomerLng = table.Column<double>(type: "float", nullable: true),
                    RestaurantAddress = table.Column<string>(type: "nvarchar(400)", maxLength: 400, nullable: true),
                    RestaurantLat = table.Column<double>(type: "float", nullable: true),
                    RestaurantLng = table.Column<double>(type: "float", nullable: true),
                    CustomerName = table.Column<string>(type: "nvarchar(120)", maxLength: 120, nullable: true),
                    CustomerPhone = table.Column<string>(type: "nvarchar(40)", maxLength: 40, nullable: true),
                    Status = table.Column<byte>(type: "tinyint", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CustomerOrders", x => x.OrderId);
                });

            migrationBuilder.CreateIndex(
                name: "IX_CustomerOrders_CustomerUserId",
                table: "CustomerOrders",
                column: "CustomerUserId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomerOrders_RestaurantId",
                table: "CustomerOrders",
                column: "RestaurantId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomerOrders_Status",
                table: "CustomerOrders",
                column: "Status");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "CustomerOrders");
        }
    }
}
