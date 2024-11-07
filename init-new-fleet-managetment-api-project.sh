#!/bin/bash

dotnet ef --version || dotnet tool install --global dotnet-ef

# Interactive prompts to guide through the process
echo "Welcome to the Fleet Management System setup!"
echo "This script will help you set up the .NET Core API, Frontend, and Database."

# Prompt for project setup
read -p "Enter your project name (default: FleetApi): " project_name
project_name=${project_name:-FleetApi}

# Create the .NET Core Web API project
echo "Creating .NET Core Web API project..."
dotnet new webapi -n $project_name

cd $project_name

# Prompt for the option to create DBContext and vehicle location model
echo "Do you want to create a DbContext and vehicle location model for database integration? (y/n)"
read -p "Enter y for Yes or n for No: " create_dbcontext
if [ "$create_dbcontext" == "y" ]; then
    echo "Creating DbContext and VehicleLocation model..."

    # Create VehicleLocation model
    mkdir -p Models
    cat <<EOL > Models/VehicleLocation.cs
using System;

namespace $project_name.Models
{
    public class VehicleLocation
    {
        public int Id { get; set; }
        public string VehicleId { get; set; }
        public decimal Latitude { get; set; }
        public decimal Longitude { get; set; }
        public DateTime Timestamp { get; set; }
    }
}
EOL

    # Create VehicleDbContext
    mkdir -p Data
    cat <<EOL > Data/VehicleDbContext.cs
using Microsoft.EntityFrameworkCore;

namespace $project_name.Data
{
    public class VehicleDbContext : DbContext
    {
        public VehicleDbContext(DbContextOptions<VehicleDbContext> options)
            : base(options) { }

        public DbSet<Models.VehicleLocation> VehicleLocations { get; set; }
    }
}
EOL

    # Update Program.cs to register DbContext
    sed -i "/builder.Services.AddControllers()/a \\
builder.Services.AddDbContext<VehicleDbContext>(options => \\
    options.UseSqlServer(builder.Configuration.GetConnectionString(\"DefaultConnection\")));" Program.cs

    # Add connection string to appsettings.json
    sed -i '/"Logging": {/a \\
  "ConnectionStrings": { \\
    "DefaultConnection": "YourDatabaseConnectionStringHere" \\
  },' appsettings.json

    echo "DbContext and model creation completed."
fi

# Prompt for running migrations
echo "Do you want to set up Entity Framework migrations? (y/n)"
read -p "Enter y for Yes or n for No: " run_migrations
if [ "$run_migrations" == "y" ]; then
    echo "Adding Entity Framework Core tools..."
    dotnet add package Microsoft.EntityFrameworkCore.SqlServer
    dotnet add package Microsoft.EntityFrameworkCore.Tools

    # Create initial migration
    dotnet ef migrations add InitialCreate

    # Update the database
    dotnet ef database update
    echo "Migrations and database setup completed."
fi

# Prompt for frontend setup
echo "Do you want to set up the frontend with Leaflet.js? (y/n)"
read -p "Enter y for Yes or n for No: " setup_frontend
if [ "$setup_frontend" == "y" ]; then
    echo "Creating simple frontend with Leaflet.js..."
    mkdir -p wwwroot
    cat <<EOL > wwwroot/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Fleet Management</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet/dist/leaflet.css" />
    <style>
        #map { height: 400px; }
    </style>
</head>
<body>
    <h1>Fleet Management Dashboard</h1>
    <div id="map"></div>
    <script src="https://unpkg.com/leaflet/dist/leaflet.js"></script>
    <script>
        var map = L.map('map').setView([51.505, -0.09], 13);

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        }).addTo(map);

        // Example marker for demonstration purposes
        L.marker([51.5, -0.09]).addTo(map)
            .bindPopup('A vehicle')
            .openPopup();
    </script>
</body>
</html>
EOL

    echo "Frontend setup completed."
fi

# Prompt for unit test setup
echo "Do you want to add unit tests using XUnit? (y/n)"
read -p "Enter y for Yes or n for No: " add_tests
if [ "$add_tests" == "y" ]; then
    echo "Adding unit tests project..."
    dotnet new xunit -n ${project_name}Tests
    cd ${project_name}Tests

    # Add necessary references for testing
    dotnet add reference ../$project_name/$project_name.csproj
    dotnet add package Microsoft.EntityFrameworkCore.InMemory
    dotnet add package Moq

    # Create sample test class
    mkdir -p Tests
    cat <<EOL > Tests/VehicleApiTests.cs
using System;
using Xunit;
using Moq;
using FleetApi.Controllers;
using Microsoft.AspNetCore.Mvc;
using FleetApi.Models;
using FleetApi.Data;
using Microsoft.EntityFrameworkCore;
using System.Linq;

namespace $project_name.Tests
{
    public class VehicleApiTests
    {
        private readonly Mock<VehicleDbContext> _mockDbContext;
        private readonly VehicleController _controller;

        public VehicleApiTests()
        {
            _mockDbContext = new Mock<VehicleDbContext>(new DbContextOptions<VehicleDbContext>());
            _controller = new VehicleController(_mockDbContext.Object);
        }

        [Fact]
        public void TestGetVehicles_ReturnsOkResult()
        {
            var result = _controller.GetVehicles();

            var okResult = Assert.IsType<OkObjectResult>(result);
            var returnValue = Assert.IsAssignableFrom<IEnumerable<VehicleLocation>>(okResult.Value);
            Assert.NotEmpty(returnValue);
        }
    }
}
EOL

    echo "Unit tests project setup completed."
fi

echo "Setup is complete! You can now develop the Fleet Management System."

dotnet restore

dotnet build

dotnet test

dotnet run
