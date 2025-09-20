# Excel Template Files

**Note**: The actual Excel (.xlsx) files are not included in this repository due to Git limitations with binary files. However, you can create them using the instructions below or download them from the releases section.

## 📊 **Available Excel Templates**

### **Cost-Analysis-Template.xlsx**
**Status**: Template structure provided - Create using instructions below
**Purpose**: Comprehensive cost analysis and visualization

### **Budget-Tracking-Template.xlsx** 
**Status**: Template structure provided - Create using instructions below
**Purpose**: Budget monitoring and variance analysis

### **Executive-Summary-Template.xlsx**
**Status**: Template structure provided - Create using instructions below  
**Purpose**: High-level executive reporting

## 🔧 **Creating the Excel Templates**

Since Excel files are binary and not ideal for Git repositories, follow these steps to create the templates:

### **Option 1: Use PowerShell Script (Recommended)**
```powershell
# Run the Excel template generator
.\scripts\utilities\Create-ExcelTemplates.ps1
```

### **Option 2: Manual Creation**

#### **1. Cost Analysis Template**
1. **Create new Excel workbook** named `Cost-Analysis-Template.xlsx`
2. **Create worksheets**: Dashboard, Raw Data, Pivot Analysis, Trends, Service Breakdown, Resource Groups, Instructions, Settings
3. **Import sample data** from `data\templates\sample-cost-data.csv` into Raw Data sheet
4. **Create pivot tables** in Pivot Analysis sheet
5. **Add charts** in Dashboard sheet
6. **Save** in `dashboards\Excel\` folder

#### **2. Budget Tracking Template**  
1. **Create new Excel workbook** named `Budget-Tracking-Template.xlsx`
2. **Create worksheets**: Budget Dashboard, Department Budgets, Monthly Tracking, Variance Analysis, Forecasting, Data Entry, Instructions
3. **Import budget data** from `data\templates\budget-template.csv`
4. **Add formulas** for variance calculations
5. **Create conditional formatting** for budget status
6. **Save** in `dashboards\Excel\` folder

#### **3. Executive Summary Template**
1. **Create new Excel workbook** named `Executive-Summary-Template.xlsx`  
2. **Create worksheets**: Executive Dashboard, KPIs, Trends, Summary, Data
3. **Add executive-level charts** and KPIs
4. **Format for printing** and presentation
5. **Save** in `dashboards\Excel\` folder

## 🚀 **Quick Template Creation Script**

I'll create a PowerShell script to generate these templates automatically:
