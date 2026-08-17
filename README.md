# 📊 Student Performance Analysis

A data analysis project exploring the relationship between student attendance,
study habits, and academic performance across subjects and classes.

## 📁 Project Structure
```
student-performance-analysis/
├── Student_Performance_Analysis.ipynb   # Main analysis notebook (fully executed)
├── student_performance.csv              # Dataset (student-subject level)
├── requirements.txt                     # Python dependencies
├── README.md                            # This file
└── .gitignore
```

## 📌 Dataset

A student-subject level dataset with the following columns:

| Column | Description |
|---|---|
| `student_id` | Unique student identifier |
| `name` | Student name |
| `gender` | Male / Female |
| `class` | Grade + section, e.g. `10-A` |
| `subject` | Subject the row's marks belong to |
| `marks` | Marks scored (0–100) |
| `attendance_percentage` | Overall attendance % |
| `study_hours` | Average daily self-study hours |


## 🔍 What's Inside the Notebook

1. Import libraries
2. Load dataset (shape, info, preview)
3. Data cleaning (missing values, duplicates, invalid values, dtype fixes)
4. Exploratory Data Analysis — subject trends, distributions, attendance vs
   marks, study hours vs marks, class-wise comparison
5. Visualizations — bar chart, pie chart, line chart, correlation heatmap
6. Factor analysis — which variables affect performance the most
7. Key insights & findings (7 data-backed takeaways)
8. Summary & actionable recommendations

## 🚀 How to Run

```bash
git clone <https://github.com/arifreha427-svg/student-performance-analysis>
cd student-performance-analysis
pip install -r requirements.txt
jupyter notebook Student_Performance_Analysis.ipynb
```

## 🛠️ Tech Stack

- Python 3
- pandas, numpy
- matplotlib, seaborn
- Jupyter Notebook

## 👤 Author

Reha Arif — Full Stack Developer & Data Analyst
