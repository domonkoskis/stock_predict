# Getting to know the data, the problem, fitting basic models only for interpretation





netflix <- read.csv("NFLX.csv")
# target ->  Adj.Close - Open ~ Difference
# could be more detailed solution (diff between the adj.closes between the days, ect.)


netflix$Difference <- netflix$Adj.Close - netflix$Open

#-----------------------------------------------------------------------------------------------------------------
# trying to get to know the data visually

#....................................................................................................................
# relationship Volume ~ Difference
library(ggplot2)
ggplot(netflix,aes(x=Volume, y = Difference)) + geom_point() +
  geom_smooth(method = lm) + geom_smooth(color = "red")
# Seems to be a weak relship -> as expected
# slope coef is almost 0 -> no signif relationship
# test is with a model

volume_diff_model <- lm(Difference ~ Volume, data = netflix)
summary(volume_diff_model)
# the partial t-tests, and the global F test shows no significat relship, as all p-values are
# bigger than any common significance levels

hist(netflix$Difference)
# seems normal -> could test it!

hist(netflix$Volume)
# long right tail -> log-transformation would be reasonable

ggplot(netflix,aes(x=log(Volume), y = Difference)) + geom_point() +
  geom_smooth(method = lm) + geom_smooth(color = "red")
# also seems to be having no relationship
# again check with a linear model

volume_diff_log_model <- lm(Difference ~ log(Volume), data = netflix)
summary(volume_diff_log_model)
# not significant

#............................................................................................................
# relationship High/Low ~ Difference
netflix$Movement <- netflix$High-netflix$Low

ggplot(netflix,aes(x=Movement, y = Difference)) + geom_point() +
  geom_smooth(method = lm) + geom_smooth(color = "red")
# also no significant felationship between highest/lowest price and diff
# no relationship between daily price movement, and diff


final_simple_model <- lm(Difference ~ Volume + Movement, data = netflix)
summary(final_simple_model)
# final conclusion
# not effective to measure them day to day
# i should analyse sequences, as a daily activity has no signif affect on price changes
#------------------------------------------------------------------------------------------------------------

# try another approach
# whether the past days movement of volume has on effect
netflix_day_before_volumes <- as.numeric(netflix[1:1008,"Volume"])
netflix_day_before_movement <- as.numeric(netflix[1:1008,"Movement"])

netflix_day_before <- netflix[2:1009,]
netflix_day_before$Volume_before <- netflix_day_before_volumes
netflix_day_before$Movement_before <- netflix_day_before_movement

# i make a column for the change in volume and movement also (+ if increased)
netflix_day_before$Volume_diff <- netflix_day_before$Volume - netflix_day_before$Volume_before
netflix_day_before$Movement_diff <- netflix_day_before$Movement - 
  netflix_day_before$Movement_before
#-------------------------------------------------------------------------------------------------------
# now analyze them first visually
hist(netflix_day_before$Volume_diff, breaks = 20)
# way too pinty to be normal, but seems to be symmetric
# volumes tent to change only a little bit between days

hist(netflix_day_before$Movement_diff, breaks = 20)
# closer to normality, but still pointy
# could check for ditributions!

#.................................................................................................
# relationship between Volume_before/Movement_before ~ Difference

ggplot(netflix_day_before,aes(x=log(Volume_before), y = Difference)) + geom_point() +
  geom_smooth(method = lm) + geom_smooth(color = "red")
ggplot(netflix_day_before,aes(x=log(Movement_before), y = Difference)) + geom_point() +
  geom_smooth(method = lm) + geom_smooth(color = "red")
# no relationship based on the plots
# we could see, that we couldnt get any useful knowladge by knowing the past volume/movemet

#..................................................................................................
# relationship between Volume_diff/Movement_diff ~ Difference

ggplot(netflix_day_before,aes(x=Volume_diff, y = Difference)) + geom_point() +
  geom_smooth(method = lm) + geom_smooth(color = "red")
# we could see that maybe if the volume has increased, than earning profit is more likely
# it is worth to check it
# we can see that mainly outliers hold the knowledge
# bigger losses or bigger wins are happening at outlier points?
# around volume_diff = 0, other factors affect difference (maybe random)
# however difference values are in a smaller range ~(-30,30)
# check the trend with a bivariate linear model

volume_day_before_diff_model <- lm(Difference ~ Volume_diff, data = netflix_day_before)
summary(volume_day_before_diff_model)
# SIGNIFICANT relationship
# intercept is not significant, can be considered 0
# very small explainatory power -> R^2 = ~1%
# i can state, that the difference todays and yesterdays volume has a positive effect on
# difference


ggplot(netflix_day_before,aes(x=Movement_diff, y = Difference)) + geom_point() +
  geom_smooth(method = lm) + geom_smooth(color = "red")
# < shape
# as movement diff increased, abs(difference) seem to increase
# same relationship could be seen between movement and difference
ggplot(netflix,aes(x=Movement, y = abs(Difference))) + geom_point() +
  geom_smooth(method = lm) + geom_smooth(color = "red")
# seems to be significant relship -> reasonable

# maximum abs(difference) possible = high-low
# minimum abs(difference) possible = 0

# if the movement of the stock prices were absolutely random, then the best fitting
# regression line would be a linear line, where diff = (high-low)/2 (B = 0.5)
netflix$Difference_abs <- abs(netflix$Difference)
diff_abs_movement_model <- lm(Difference_abs ~ Movement, data = netflix) 
summary(diff_abs_movement_model)
# strong and significant relationship
# however B1 = 0.6745 >> 0.5!
# so more difference gets into the [(high-low)/2,high-low] category

# economic conclusion
# if a stock price reaches a daily min or max, the final price will more likely be close to
# the extremums, rather than their average

# lets create a candle diagram like movement measure
# + (green) if stock price increased, - (red) if decreased
netflix$Movement_new <- ifelse(netflix$Difference < 0, -1*netflix$Movement,
                               netflix$Movement)
ggplot(netflix,aes(x=Movement_new, y = Difference)) + geom_point() +
  geom_smooth(method = lm) + geom_smooth(color = "red")
movement_new_model <- lm(Difference ~ Volume + I(Movement_new), data = netflix)
summary(movement_new_model)

# Final conclusion:
# current data couldn explain anything from current prices, as it it logically expected
# Even past data (day before only) has small explainatory power
# With these fabricated variables, it is not worth to fit a regression model
# In addition it is more like a classification problem, but the time variable has an impact
# Even time series analysis


#--------------------------------------------------------------------------------------------------------
# New approach 
# Engineering more economicly and statistically interpretable lagged indicators/variables
# Classification
# Then model evaluation
#--------------------------------------------------------------------------------------------------------
# New target variable
# 1 if next day the price goes up, zero when decreases

df <- read.csv("NFLX.csv")

df$Date <- as.Date(df$Date)
df <- df[order(df$Date), ]

df$t <- 1:nrow(df)

ggplot(df, aes(x=Date)) + geom_line(aes(y=Close)) + theme_minimal()


df$Return <- log(df$Adj.Close / dplyr::lag(df$Adj.Close))
# Log return

hist(df$Return)

df$Direction <- ifelse(df$Return > 0, 1, 0)
table(df$Direction)
#-----------------------------------------------------------------------------------------------------
# New lagged and economicly interpredable predictors

library(dplyr)
library(TTR)
library(zoo)

df <- df %>%
  mutate(
    Ret_1 = lag(Return, 1),
    Ret_5 = rollapply(Return, 5, mean, fill = NA, align = "right"),
    Vol_1 = lag(Volume, 1),
    Vol_5 = rollapply(Volume, 5, mean, fill = NA, align = "right"),
    HL_Range = (High - Low) / Open,
    HL_1 = lag(HL_Range, 1),
    Volatility_5 = rollapply(Return, 5, sd, fill = NA, align = "right")
  )

# New model lm
model <- lm(Direction ~ Ret_1 + Ret_5 + Vol_1 + Vol_5 + HL_1 + Volatility_5,
             data = df)
summary(model)
# problem -> not 0 or 1, it can predict below 0 or above 1 for example
min(model$fitted.values)
max(model$fitted.values)
# Solution -> binomial model

model_glm <- glm(Direction ~ Ret_1 + Ret_5 + Vol_1 + Vol_5 + HL_1 + Volatility_5,
             data = df, family = binomial)
summary(model_glm)
min(model_glm$fitted.values)
max(model_glm$fitted.values)

sjPlot::plot_model(model, type = "pred", terms = c("Ret_1", "Ret_5"))
# Predicts directions not only between 0-1

sjPlot::plot_model(model_glm, type = "pred", terms = c("Ret_1", "Ret_5"))
# Nice
#-----------------------------------------------------------------------------------------------------------
# Proper evaluation

library(caret)

df_clean <- na.omit(df)

# set.seed(123)


train <- df_clean[1:(0.7*nrow(df)), ]
test  <- df_clean[(0.7*nrow(df)+1):nrow(df), ]

model_netflix <- glm(Direction ~ Ret_1 + Ret_5 + Vol_1 + Vol_5 + HL_1 + Volatility_5,
                     data = train, family = binomial)
pred <- predict(model_netflix, newdata = test, type = "response")
pred_class <- ifelse(pred > 0.5, 1, 0)
table(Predicted = pred_class,Real = test$Direction)


confusionMatrix(as.factor(pred_class), as.factor(test$Direction))

# 68,79% accuracy
# Seems to0 beautiful to be true

# Visualize the price predictions
model_netflix_price <- lm(Adj.Close ~ Ret_1 + Ret_5 + Vol_1 + Vol_5 + HL_1 + Volatility_5,
                          data = df)
summary(model_netflix_price)

ggplot(df_clean, aes(x=Date)) + geom_line(aes(y=Adj.Close, col = "Real")) + 
  geom_line(aes(y=model_netflix_price$fitted.values, col = "Predicted")) +
  theme_minimal()


# Classification isualization

# ROC curve
library(pROC)

roc_obj <- roc(test$Direction, pred)

plot(roc_obj, col = "blue", lwd = 3,
     main = "ROC Curve for Stock Direction Model")

auc(roc_obj)

best <- coords(roc_obj, "best", ret = c("threshold", "sensitivity", "specificity"))
best # treshold close to 0.5, seems reasonable



# test for other datasets too

nvidia <- read.csv("NVIDIA_STOCK.csv")
nvidia <- nvidia[3:1699,]

options(digits = 15)

colnames(nvidia)[1] <- c("Date")
nvidia$Date <- as.Date(nvidia$Date)
nvidia$Adj.Close <- as.numeric(nvidia$Adj.Close)
nvidia$Close <- as.numeric(nvidia$Close)
nvidia$High <- as.numeric(nvidia$High)
nvidia$Low <- as.numeric(nvidia$Low)
nvidia$Open <- as.numeric(nvidia$Open)
nvidia$Volume <- as.integer(nvidia$Volume)

nvidia$Return <- log(nvidia$Adj.Close / dplyr::lag(nvidia$Adj.Close))

nvidia$Direction <- ifelse(nvidia$Return > 0, 1, 0)

ggplot(nvidia, aes(x=Date, y=Adj.Close)) + geom_line() + theme_minimal()

nvidia <- nvidia %>%
  mutate(
    Ret_1 = lag(Return, 1),
    Ret_5 = rollapply(Return, 5, mean, fill = NA, align = "right"),
    Vol_1 = lag(Volume, 1),
    Vol_5 = rollapply(Volume, 5, mean, fill = NA, align = "right"),
    HL_Range = (High - Low) / Open,
    HL_1 = lag(HL_Range, 1),
    Volatility_5 = rollapply(Return, 5, sd, fill = NA, align = "right")
  )

nvidia_clean <- na.omit(nvidia)

train <- nvidia_clean[1:round(0.7*nrow(nvidia_clean)), ]
test  <- nvidia_clean[(round(0.7*nrow(nvidia_clean))+1):nrow(nvidia_clean), ]




model_glm_nvidia <- glm(Direction ~ Ret_1 + Ret_5 + Vol_1 + Vol_5 + HL_1 + Volatility_5,
                 data = train, family = binomial)
summary(model_glm_nvidia)







pred <- predict(model_glm_nvidia, newdata = test, type = "response")
pred_class <- ifelse(pred > 0.5, 1, 0)

confusionMatrix(as.factor(pred_class), as.factor(test$Direction))

# 66% accuracy
# But captures decreses only 50% accurately
# Visualization

roc_obj <- roc(test$Direction, pred)

plot(roc_obj, col = "blue", lwd = 3,
     main = "ROC Curve for Stock Direction Model")

auc(roc_obj)

best <- coords(roc_obj, "best", ret = c("threshold", "sensitivity", "specificity"))
best   # best around 0.65

# Test for other stock data

#...

