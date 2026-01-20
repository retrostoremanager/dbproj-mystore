#!/usr/bin/env pwsh
# Manual deployment script for PostgreSQL schema

$serverName = "mystore-postgres-dev"
$databaseName = "mystore-db-dev"
$adminUser = "sqladmin"
$adminPassword = "MySecureDevPW`$1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Manual PostgreSQL Schema Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$sqlFiles = @(
    "001_create_company_table.sql",
    "002_create_customer_table.sql",
    "003_create_employee_table.sql",
    "004_create_game_table.sql",
    "005_create_inventory_item_table.sql",
    "006_create_sale_table.sql",
    "007_create_sale_item_table.sql",
    "010_create_company_functions.sql"
)

$successCount = 0
$failCount = 0

foreach ($sqlFile in $sqlFiles) {
    $filePath = Join-Path "PostgreSQL" $sqlFile
    
    if (-not (Test-Path $filePath)) {
        Write-Host "[ERROR] File not found: $sqlFile" -ForegroundColor Red
        $failCount++
        continue
    }
    
    Write-Host "Executing: $sqlFile" -ForegroundColor Cyan
    
    try {
        # Read SQL content
        $sqlContent = Get-Content $filePath -Raw
        
        # Execute using Azure CLI
        $result = az postgres flexible-server execute `
            --name $serverName `
            --admin-user $adminUser `
            --admin-password $adminPassword `
            --database-name $databaseName `
            --querytext $sqlContent `
            2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SUCCESS] $sqlFile deployed" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "[ERROR] Failed to deploy $sqlFile" -ForegroundColor Red
            Write-Host $result -ForegroundColor Red
            $failCount++
        }
        
    } catch {
        Write-Host "[ERROR] Exception deploying $sqlFile : $_" -ForegroundColor Red
        $failCount++
    }
    
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Success: $successCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor Red
Write-Host ""

if ($failCount -gt 0) {
    Write-Host "[ERROR] Schema deployment completed with errors" -ForegroundColor Red
    exit 1
} else {
    Write-Host "[SUCCESS] Schema deployment completed successfully!" -ForegroundColor Green
    exit 0
}
