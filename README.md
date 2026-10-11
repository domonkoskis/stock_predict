[README_stockpred.md](https://github.com/user-attachments/files/33307351/README_stockpred.md)
# Stock Price Direction Modelling with Linear & Logistic Regression (R)

An exploratory statistical modelling project in R that investigates whether daily stock market data (price, volume, intraday range) can explain or predict stock price movements. The analysis starts with simple linear regression on **Netflix (NFLX)** data, shows why that approach falls short, and then moves to **logistic regression** with engineered, lagged predictors to classify the daily price direction. The final model is also re-tested on **NVIDIA** data.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Repository Structure](#repository-structure)
- [Data](#data)
- [Requirements](#requirements)
- [How to Run](#how-to-run)
- [Methodology](#methodology)
  - [1. Exploratory Linear Models](#1-exploratory-linear-models)
  - [2. Using the Previous Day's Data](#2-using-the-previous-days-data)
  - [3. Classification with Logistic Regression](#3-classification-with-logistic-regression)
  - [4. Model Evaluation](#4-model-evaluation)
  - [5. Testing on NVIDIA](#5-testing-on-nvidia)
- [Key Findings](#key-findings)
- [Known Limitations](#known-limitations)
- [Possible Improvements](#possible-improvements)

---

## Project Overview

The central question is:

> Can we explain or predict the daily performance of a stock using simple market indicators?

The script walks through the thinking process step by step:

1. Define a simple target (`Difference = Adj.Close - Open`) and explore it visually and with linear models.
2. Check whether the previous day's volume and price movement carry any information.
3. Realise that the problem is better framed as **classification** (price goes up vs. down) and not regression.
4. Engineer lagged / rolling indicators and fit a **logistic regression** model.
5. Evaluate it with a train/test split, a confusion matrix and a ROC curve.
6. Repeat the pipeline on a second stock (NVIDIA).

## Repository Structure

```
.
├── Stock_Price_LRM.R      # Main analysis script
├── NFLX.csv               # Netflix historical stock data (input)
├── NVIDIA_STOCK.csv       # NVIDIA historical stock data (input)
└── README.md
```

> Adjust the file names/paths above to match your repository.

## Data

The script expects two CSV files in the working directory with daily OHLCV data:

| File | Description |
|------|-------------|
| `NFLX.csv` | Netflix daily stock data (~1,000 trading days) |
| `NVIDIA_STOCK.csv` | NVIDIA daily stock data (~1,700 trading days). The first rows are trimmed in the script (`nvidia[3:1699, ]`) because of the header format of the file. |

Expected columns: `Date`, `Open`, `High`, `Low`, `Close`, `Adj.Close`, `Volume`.

Data of this kind can be downloaded from sources such as Yahoo Finance or Kaggle.

## Requirements

- **R** (version 4.0 or newer recommended)
- R packages:

| Package | Used for |
|---------|----------|
| `ggplot2` | Visualisation (scatter plots, time series) |
| `dplyr` | Data manipulation, `lag()` |
| `zoo` | Rolling-window statistics (`rollapply`) |
| `TTR` | Technical trading rules (loaded, optional) |
| `caret` | Confusion matrix and classification metrics |
| `pROC` | ROC curve, AUC, optimal threshold |
| `sjPlot` | Plotting predicted probabilities from models |

Install everything with:

```r
install.packages(c("ggplot2", "dplyr", "zoo", "TTR", "caret", "pROC", "sjPlot"))
```

## How to Run

1. Clone the repository:
   ```bash
   git clone https://github.com/<your-username>/<your-repo>.git
   cd <your-repo>
   ```
2. Put `NFLX.csv` and `NVIDIA_STOCK.csv` in the same folder as the script.
3. Open `Stock_Price_LRM.R` in RStudio, set the working directory to the script's location (`Session > Set Working Directory > To Source File Location`), and run it section by section.

The script is written as an interactive, commented analysis, so it is best run step by step so that each plot and model summary can be inspected.

## Methodology

### 1. Exploratory Linear Models

- **Target:** `Difference = Adj.Close - Open` (the daily gain or loss).
- Visualised `Difference` against `Volume` (raw and log-transformed) and against the daily price range `Movement = High - Low`.
- Fitted simple linear models (`lm`) and checked the t-tests and global F-test.
- Examined distributions with histograms (`Difference` looks roughly normal, `Volume` has a long right tail, which motivates a log transform).

**Result:** neither volume nor daily price range has a significant linear relationship with the daily gain/loss.

### 2. Using the Previous Day's Data

- Built "day before" variables (`Volume_before`, `Movement_before`) and day-over-day changes (`Volume_diff`, `Movement_diff`).
- The change in volume (`Volume_diff`) showed a **statistically significant but very weak** positive effect on `Difference` (R² ≈ 1%).
- Modelled the **absolute** gain/loss `|Difference|` against `Movement`: a strong, significant relationship with slope ≈ **0.67**. If the closing price were uniformly random within the day's range, the slope would be about 0.5, so the closing price tends to land closer to the daily extremes than to the middle of the range.
- Created a signed, candlestick-like movement measure (`Movement_new`: positive for green days, negative for red days).

**Conclusion:** same-day data cannot meaningfully explain price changes with a regression model, and the problem is more naturally a **classification** problem with a time component.

### 3. Classification with Logistic Regression

- **Target:** `Direction` = 1 if the daily log return is positive, 0 otherwise.
- **Log return:** `Return = log(Adj.Close_t / Adj.Close_{t-1})`.
- **Engineered features:**

| Feature | Meaning |
|---------|---------|
| `Ret_1` | Previous day's return |
| `Ret_5` | 5-day rolling mean of returns |
| `Vol_1` | Previous day's volume |
| `Vol_5` | 5-day rolling mean of volume |
| `HL_1` | Previous day's (High − Low) / Open range |
| `Volatility_5` | 5-day rolling standard deviation of returns |

- A linear probability model (`lm`) produces fitted values outside [0, 1], so a **binomial GLM** (`glm(..., family = binomial)`) is used instead. Predicted probabilities for both models are compared with `sjPlot::plot_model`.

### 4. Model Evaluation

- Time-ordered split: first **70%** of observations for training, last **30%** for testing (no random shuffling, to respect the time structure).
- Evaluation with a **confusion matrix** (`caret::confusionMatrix`), a **ROC curve** and **AUC** (`pROC`), and the optimal classification threshold (`coords(..., "best")`).
- Netflix reported accuracy: about **68.8%**.

### 5. Testing on NVIDIA

The same pipeline (cleaning, feature engineering, 70/30 split, logistic regression, confusion matrix, ROC/AUC) is applied to NVIDIA data.

- Reported accuracy: about **66%**, but the model identifies price **decreases** only about 50% of the time.
- The optimal ROC threshold is around **0.65**.

## Key Findings

- Contemporaneous variables (volume, daily range) have essentially no linear relationship with the day's gain or loss.
- The daily range strongly relates to the *size* of the move (`|Difference|`), not its *direction*.
- Framing the task as classification with lagged and rolling indicators is more appropriate than regression on price differences.
- A logistic regression gives valid probabilities, whereas a linear model does not.
- The reported accuracies look surprisingly high for stock direction prediction, which is a warning sign (see below).

## Known Limitations

Daily stock direction is notoriously hard to predict, so the results above should be treated with scepticism. Please note the following points in the current script:

1. **Possible look-ahead leakage in rolling features.** `Ret_5` and `Volatility_5` use `rollapply(..., align = "right")`, which includes the *current* day's return, the very quantity used to define `Direction`. The same applies to `Vol_5` with the current day's volume. These features should be lagged by one day (e.g. `lag(Ret_5, 1)`) to use only past information. This likely explains the "too good to be true" accuracy.
2. **Train/test split indices.** For Netflix the split is computed from `nrow(df)` but applied to `df_clean` (after removing `NA` rows), so the split is not exactly 70/30.
3. **Target definition.** The comments describe predicting the *next* day's direction, but `Direction` is defined from the *same* day's return.
4. **Price regression plot.** The `Adj.Close ~ ...` linear model is fitted on `df` (with `NA`s dropped by `lm`) and plotted against `df_clean`; the price level is non-stationary, so this fit is not a meaningful forecast.
5. The accuracy metric alone is misleading when classes are imbalanced; also consider balanced accuracy, sensitivity/specificity and AUC.

## Possible Improvements

- Fix the leakage issues above and re-evaluate. Expect accuracy to drop closer to ~50–55%.
- Use proper time-series cross-validation (rolling/expanding window) instead of a single split.
- Add technical indicators (RSI, MACD, moving averages) via the `TTR` package.
- Try other classifiers (regularised logistic regression, random forest, gradient boosting).
- Compare against a naive baseline (always predicting the majority class).
- Extend the analysis to more stocks (the script has a placeholder for this) and wrap the pipeline into a reusable function.
- Explore time-series models (ARIMA/GARCH) for returns and volatility.

## Disclaimer

This project is for educational purposes only and does not constitute financial advice.
