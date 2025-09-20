# Excel Dashboard Templates for Azure Cost Management

Professional Excel templates for organizations that need comprehensive cost analysis without Power BI licensing requirements.

## Available Templates

### Cost Analysis Dashboard (`CostAnalysisDashboard.xlsx`)
**Purpose**: Complete cost visibility and trend analysis
**Key Features**:
- Automated data refresh from CSV exports
- Interactive pivot tables with drill-down capability
- Month-over-month variance analysis
- Service and resource group breakdowns
- Cost trend visualization with forecasting
**Best For**: Finance analysts, cost center managers, monthly reporting

### Budget Tracking Dashboard (`BudgetTrackingDashboard.xlsx`)
**Purpose**: Budget monitoring and variance management
**Key Features**:
- Budget vs actual comparison with alerts
- Department-level budget allocation
- Quarterly projection calculations
- Conditional formatting for budget status
- Variance analysis with root cause tracking
**Best For**: Finance teams, department managers, budget planning

### Executive Summary Report (`ExecutiveSummaryReport.xlsx`)
**Purpose**: High-level strategic cost reporting
**Key Features**:
- Single-page executive dashboard
- Key performance indicators (KPIs)
- Cost optimization recommendations
- Print-ready formatting for presentations
- Automated summary calculations
**Best For**: C-level executives, board presentations, stakeholder reports

## Quick Start Setup

### Prerequisites
- Excel 2016 or later (Excel 365 recommended)
- Macro-enabled workbooks support (.xlsm files)
- CSV export capability from Azure Cost Management

### Initial Setup Process

1. **Download and Enable**
   ```
   • Download your required template
   • Open Excel and enable macros when prompted
   • Save the file to your preferred location
   • Review the 'Instructions' worksheet
   ```

2. **Data Connection Setup**
   ```
   • Generate CSV export using: Get-AzureCostData.ps1 -Format CSV
   • In Excel: Data → Get Data → From Text/CSV
   • Select your cost data CSV file
   • Configure data types and relationships
   • Save the data connection for future refreshes
   ```

3. **Initial Validation**
   ```
   • Verify data loaded correctly in 'Raw Data' worksheet
   • Check date ranges and cost amounts
   • Refresh all calculations (Ctrl+Alt+F9)
   • Review dashboard for any error indicators
   ```

## Template Architecture

### Cost Analysis Dashboard Structure
```
CostAnalysisDashboard.xlsx
├── Executive Summary     (High-level overview)
├── Cost Dashboard       (Main analytical view)
├── Service Analysis     (By Azure service type)
├── Resource Groups      (By resource group)
├── Trend Analysis       (Historical patterns)
├── Raw Data            (Imported cost data)
└── Configuration       (Settings and parameters)
```

### Key Calculations and Formulas

#### Essential Cost Metrics
```excel
# Monthly Total Cost
=SUMIFS(RawData[Cost], RawData[Date], ">="&EOMONTH(TODAY(),-1)+1, RawData[Date], "<="&EOMONTH(TODAY(),0))

# Month-over-Month Growth
=IFERROR((ThisMonth-LastMonth)/ABS(LastMonth), 0)

# Service Cost Distribution
=RawData[Cost]/SUMIF(RawData[Date], ">="&StartDate, RawData[Cost])

# Budget Utilization
=ActualCost/BudgetAmount

# Cost per Resource
=SUMIF(RawData[ResourceGroup], ResourceGroupName, RawData[Cost])/COUNTIF(RawData[ResourceGroup], ResourceGroupName)
```

#### Conditional Formatting Rules
```excel
# Budget Status Indicators
Green (≤75% of budget): <=0.75
Yellow (76-90% of budget): >0.75 AND <=0.90
Red (>90% of budget): >0.90

# Cost Trend Indicators
Increasing (↑): >105% of previous period
Stable (→): 95% to 105% of previous period
Decreasing (↓): <95% of previous period
```

## Data Import and Refresh

### Automated CSV Import
Configure Power Query for seamless data updates:

```excel
1. Data → Get Data → From Text/CSV
2. Browse to your cost data export location
3. Configure column data types:
   • Date: Date format
   • Cost: Currency or Number
   • Tags: Text
4. Load to existing table in 'Raw Data' worksheet
5. Save query for future refreshes
```

### PowerShell Integration
Combine with PowerShell scripts for end-to-end automation:

```powershell
# Generate fresh cost data and refresh Excel
.\Export-AzureCostData.ps1 -Days 30 -OutputPath "CostData.csv"

# Open Excel file and refresh data connections
$excel = New-Object -ComObject Excel.Application
$workbook = $excel.Workbooks.Open("$PWD\CostAnalysisDashboard.xlsx")
$workbook.RefreshAll()
$workbook.Save()
$excel.Quit()
```

### Manual Data Entry Option
For scenarios requiring manual input:

1. Navigate to 'Data Entry' worksheet
2. Follow the provided column format
3. Use data validation dropdowns for consistency
4. Click 'Validate Data' button before proceeding
5. Refresh dashboards using 'Update All' button

## Advanced Features

### VBA Automation (Optional)
Enhance templates with custom macros:

```vb
Sub RefreshAllData()
    Application.ScreenUpdating = False
    
    ' Refresh external data connections
    ActiveWorkbook.RefreshAll
    
    ' Update timestamp
    Range("LastRefreshTime").Value = Now()
    
    ' Recalculate formulas
    Application.CalculateFullRebuild
    
    ' Update status
    Range("RefreshStatus").Value = "Data refreshed at " & Format(Now(), "yyyy-mm-dd hh:mm")
    
    Application.ScreenUpdating = True
    MsgBox "Cost data refresh completed successfully!"
End Sub

Sub ExportExecutiveSummary()
    Dim ws As Worksheet
    Set ws = Worksheets("Executive Summary")
    
    ' Export to PDF
    ws.ExportAsFixedFormat _
        Type:=xlTypePDF, _
        Filename:="ExecutiveCostSummary_" & Format(Date, "yyyymmdd") & ".pdf", _
        Quality:=xlQualityStandard
        
    MsgBox "Executive summary exported to PDF!"
End Sub
```

### Custom KPI Calculations
Build organization-specific metrics:

```excel
# Cost per Employee
=TotalMonthlyCost/EmployeeCount

# Cloud Efficiency Ratio
=ProductionCost/(ProductionCost+DevelopmentCost)

# Service Utilization Score
=SUMPRODUCT(ServiceUsage*ServiceCost)/SUM(ServiceCost)

# Budget Forecast Accuracy
=1-ABS((ForecastedCost-ActualCost)/ActualCost)
```

## Common Use Cases

### Monthly Financial Close
**Process Flow**:
1. Export previous month's cost data using PowerShell
2. Import into Cost Analysis Dashboard
3. Review variance analysis and anomalies
4. Generate executive summary report
5. Distribute to finance team and stakeholders

**Key Deliverables**:
- Month-end cost summary
- Variance explanation report
- Service-level cost breakdown
- Budget utilization status

### Department Chargeback
**Process Flow**:
1. Filter cost data by department tags
2. Export department-specific breakdowns
3. Calculate chargeback amounts using Budget template
4. Generate individual department reports
5. Send to department managers for review

**Key Deliverables**:
- Department cost allocation
- Service usage by department
- Chargeback invoices
- Utilization efficiency metrics

### Cost Optimization Analysis
**Process Flow**:
1. Analyze 90-day cost trends by service
2. Identify top cost drivers and anomalies
3. Compare costs across environments
4. Document optimization opportunities
5. Track savings from implemented changes

**Key Deliverables**:
- Cost optimization recommendations
- Savings opportunity analysis
- Environment comparison report
- ROI tracking for optimization efforts

## Troubleshooting

### Data Import Issues
**Problem**: CSV import fails or shows errors
**Solutions**:
- Verify CSV format matches expected structure
- Check for special characters in cost amounts
- Ensure date formats are consistent (YYYY-MM-DD)
- Validate file permissions and accessibility

**Problem**: Formulas showing #REF! or #VALUE! errors
**Solutions**:
- Check named ranges in Formula → Name Manager
- Verify data types match formula expectations
- Ensure all referenced worksheets exist
- Update cell references if data structure changed

### Performance Optimization
**For Large Datasets** (>50K rows):
- Enable manual calculation mode (Formulas → Calculation Options → Manual)
- Use structured tables instead of cell ranges
- Limit conditional formatting to essential cells only
- Consider splitting data across multiple workbooks by time period

**Memory Management**:
- Close unused applications while working with large files
- Save frequently to prevent data loss
- Use 64-bit Excel for datasets larger than 100K rows
- Consider Power Query for data transformation instead of formulas

### Macro Security
**Issue**: Macros disabled or not working
**Resolution**:
1. File → Options → Trust Center → Trust Center Settings
2. Macro Settings → Enable all macros (for trusted files)
3. Save file as .xlsm (macro-enabled workbook)
4. Add file location to Trusted Locations if needed

## Customization Guide

### Adding Custom Charts
```excel
1. Select your data range
2. Insert → Charts → Choose appropriate chart type
3. Apply consistent formatting:
   • Font: Segoe UI, 10pt
   • Colors: Azure theme palette
   • Remove unnecessary gridlines
4. Position on dashboard worksheet
5. Link chart title to dynamic cell reference
```

### Custom Conditional Formatting
Create visual indicators for cost thresholds:

```excel
# High Cost Alert (>$1000)
Format: Red fill, bold text
Formula: =AND(CostValue>1000, CostValue<>"")

# Budget Warning (>80% of budget)
Format: Yellow fill, dark text
Formula: =CostValue/BudgetValue>0.8

# Savings Opportunity (decreasing trend)
Format: Green fill, white text
Formula: =TrendValue<-0.05
```

### Branding and Styling
**Color Palette**:
- Primary: #0078D4 (Azure Blue)
- Secondary: #106EBE (Dark Blue)  
- Success: #107C10 (Green)
- Warning: #FF8C00 (Orange)
- Error: #D13438 (Red)
- Neutral: #605E5C (Gray)

**Typography**:
- Headers: Segoe UI Semibold, 14pt
- Body text: Segoe UI, 11pt
- Data values: Segoe UI, 10pt

## Support and Resources

### Template Support
- **Documentation**: Complete user guides included in each template
- **Issues**: Report template bugs with specific error messages
- **Customization**: Contact wes@wesellis.com for custom template development
- **Training**: Excel training resources available for complex features

### Best Practices
- **Data Backup**: Save original templates before customization
- **Version Control**: Use descriptive file names with dates
- **Testing**: Validate formulas with known data before production use
- **Security**: Protect sensitive worksheets and consider file encryption

### Update Process
- **Monthly**: Check for template updates and new features
- **Quarterly**: Review custom formulas for accuracy
- **Annually**: Validate data connections and refresh procedures

---

**Templates provide complete Azure cost analysis functionality in Excel when Power BI is not available. Each template includes comprehensive documentation, examples, and support for immediate deployment.**
