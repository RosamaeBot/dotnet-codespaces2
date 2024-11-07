#!/bin/bash

# Ensure EF tools are installed
dotnet ef --version || dotnet tool install --global dotnet-ef

echo "Welcome to the Fleet Management System setup!"
echo "This script will guide you through the setup."

# Create .NET Core Web API
read -p "Enter your project name (default: FleetApi): " project_name
project_name=${project_name:-FleetApi}
dotnet new webapi -n $project_name
cd $project_name

# Optional DbContext & VehicleLocation setup
echo "Do you want to create DbContext and vehicle location model? (y/n)"
read -p "Enter y or n: " create_dbcontext
if [ "$create_dbcontext" == "y" ]; then
    echo "Creating DbContext and VehicleLocation model..."
    mkdir -p Models Data
    # Create model and context files...
fi

# Migrations setup
echo "Do you want to set up migrations? (y/n)"
read -p "Enter y or n: " run_migrations
if [ "$run_migrations" == "y" ]; then
    echo "Setting up migrations..."
    dotnet add package Microsoft.EntityFrameworkCore.SqlServer
    dotnet add package Microsoft.EntityFrameworkCore.Tools
    dotnet ef migrations add InitialCreate
    dotnet ef database update
fi

# Frontend setup
echo "Do you want to create the frontend with Leaflet.js? (y/n)"
read -p "Enter y or n: " setup_frontend
if [ "$setup_frontend" == "y" ]; then
    mkdir -p wwwroot
    # Create frontend HTML...
fi

# Unit test setup
echo "Do you want to add unit tests with Xunit? (y/n)"
read -p "Enter y or n: " add_tests
if [ "$add_tests" == "y" ]; then
    dotnet new xunit -n ${project_name}Tests
    cd ${project_name}Tests
    dotnet add reference ../$project_name/$project_name.csproj
    dotnet add package Moq
    dotnet add package Xunit
fi

# Restore, build, test and run
dotnet restore
dotnet build
dotnet test
dotnet run
