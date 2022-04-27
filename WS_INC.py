#!/usr/bin/env python
# coding: utf-8

# In[15]:



# load and plot dataset
import pandas
from pandas import read_csv
from datetime import datetime
from pandas import DataFrame
from matplotlib import pyplot
from pandas.plotting import autocorrelation_plot
import statsmodels
from statsmodels.graphics.tsaplots import plot_pacf
from statsmodels.graphics.tsaplots import plot_acf
from statsmodels.tsa.arima.model import ARIMA
from statsmodels.tsa.arima.model import ARIMAResults
from math import sqrt
#import math
from sklearn.metrics import mean_squared_error
import numpy
import warnings
from statsmodels.tools.sm_exceptions import ConvergenceWarning
import pickle
warnings.filterwarnings("ignore")
from sklearn.metrics import mean_squared_error


# In[16]:


# # load dataset
# Using the csv format for the

series = read_csv(r'C:\Users\rkhan\Documents\MIRACL\ARIMA_Forecasting_Python\Time_Series\WS_TV\WS_TV.csv',
                  header=0, index_col=0, parse_dates=True,)
series.squeeze()
series.plot()
pyplot.show()

# removed last 24 datapoints for final validation towards the end.
split_point = len(series) - 838 ## To start from 2001 datapoint
dataset, validation = series[0:split_point], series[split_point:2222]
input1 =series[2222:]
#dataset.extend(input1) 
#dataset = numpy.append (dataset, input1)
dataset = dataset.append (input1)

print(dataset)
print(validation)
print('Dataset %d, Validation %d' % (len(dataset), len(validation)))
dataset.to_csv('dataset.csv')
validation.to_csv('validation.csv')


# In[17]:



#acf and pacf
autocorrelation_plot(series)
pyplot.show()
plot_acf(series)
plot_pacf(series)
pyplot.show()


# In[18]:



# fit an ARIMA model and plot residual errors

# load dataset

series = read_csv('dataset.csv', header=0, index_col=0, parse_dates=True,)  # add cart data
series.squeeze()
# fit model
# update values as per acf and pacf values, keep d close to 1
model = ARIMA(series, order=(5, 1, 2)).fit()
#model_fit = model.fit()
# summary of fit model
print(model.summary())
# line plot of residuals
residuals = DataFrame(model.resid)
residuals.plot()
pyplot.show()
# density plot of residuals
residuals.plot(kind='kde')
pyplot.show()
# summary stats of residuals
print(residuals.describe())


# In[20]:



# evaluate an ARIMA model using a walk-forward validation

# load dataset
# add dataset for CART

warnings.filterwarnings('ignore', 'statsmodels.tsa.arima.model.ARMA',
                        FutureWarning)
warnings.filterwarnings('ignore', 'statsmodels.tsa.arima.model.ARIMA',
                        FutureWarning)

# split into train and test sets
X = series.values
size = int(len(X) * 0.75)  # try for 0.75 and 0.80 split for accuracy
train, test = X[0:size], X[size:len(X)]
history = [x for x in train]
predictions = list()


# In[21]:




# walk-forward validation
for t in range(len(test)):
    model = ARIMA(history, order=(5, 1, 2)).fit()
# update as per acf and pacf
    output = model.forecast()
    yhat = output[0]
    predictions.append(yhat)
    # print(yhat)
    obs = test[t]
    history.append(obs)
    print('predicted=%f, expected=%f' % (yhat, obs))


# In[22]:


# evaluate forecasts
rmse = sqrt(mean_squared_error(test, predictions))
print('Test RMSE: %.3f' % rmse)
# plot forecasts against actual outcomes
pyplot.plot(test)
pyplot.plot(predictions, color='red')
pyplot.show()


# In[23]:



# save finalized model to file

# monkey patch around bug in ARIMA class


def __getnewargs__(self):
    return ((self.endog), (self.k_lags, self.k_diff, self.k_ma))
    ARIMA.__getnewargs__ = __getnewargs__


# In[24]:


# load data


series = read_csv('dataset.csv', header=0, index_col=0,
                  parse_dates=True)
series.squeeze()


# In[25]:



# prepare data
X = series.values
X = X.astype('float32')


# In[26]:



# fit model
model = ARIMA(X, order=(5, 1, 2)).fit()

# bias constant, could be calculated from in-sample mean residual
trial = model.forecast(4)[0]
print(trial)
bias = 0.008994

# print(trial)


# In[27]:



# save model
model.save('model.pkl')
numpy.save('model_bias.npy', [bias])

# with open('model.pkl','wb') as f:
#    pickle.dump(X,f)
#model_fit = ARIMAResults.load(open('model.pkl','rb'))


# In[28]:



# load finalized model and make a prediction

dataset = read_csv('dataset.csv', header=0, index_col=0,parse_dates=True)
dataset.squeeze()
X = dataset.values.astype('float32')
history = [x for x in X]
validation = read_csv('validation.csv', header=0, index_col=0, parse_dates=True,)
validation.squeeze()
y = validation.values.astype('float32')


# In[29]:


#model= pickle.load(open('model.pkl','rb'))
# model.forecast(X)

model_fit = ARIMAResults.load('model.pkl')
bias = numpy.load('model_bias.npy')
# first prediction
predictions = list()
yhat = bias + float(model_fit.forecast()[0])
predictions.append(yhat)
history.append(y[0])
print('>Predicted=%.3f, Expected=%.3f' % (yhat, y[0]))

for i in range(1, len(y)):
    # predict
    model = ARIMA(history, order=(5, 1, 2)).fit()
   

  #  model_fit = model.fit()
    yhat = bias + float(model.forecast()[0])
    predictions.append(yhat)
    # observation
    obs = y[i]
    history.append(obs)
    import warnings
    warnings.simplefilter('ignore', ConvergenceWarning)
    print('>Predicted=%.3f, Expected=%0.3f' % (yhat, obs))


# In[30]:




# report performance
#rmse =sqrt(mean_squared_error(y, predictions))
rmse = sqrt(mean_squared_error(y[25:], predictions[25:]))

print('RMSE: %.3f' % rmse)
pyplot.plot(y[25:])
pyplot.plot(predictions[25:], color='red')
pyplot.show()

numpy.savetxt(r"C:\Users\rkhan\Documents\MIRACL\ARIMA_Forecasting_Python\Time_Series\predictions.csv", predictions, delimiter=",")


# In[ ]:


print(len(series))


# In[ ]:


split_point = len(series) - 879


# In[ ]:


print(split_point)


# In[ ]:


# # load dataset
# Using the csv format for the
series = read_csv(r'C:\Users\rkhan\Documents\MIRACL\ARIMA_Forecasting_Python\Time_Series\GHI_TV.csv',
                  header=0, index_col=0, parse_dates=True,)
series.squeeze()
series.plot()
pyplot.show()

# removed last 24 datapoints for final validation towards the end.
split_point = len(series) - 879 ## To start from 2001 datapoint
dataset, validation = series[0:split_point], series[split_point:2181]
input1 =series[2181:]
#dataset.extend(input1) 
#dataset = numpy.append (dataset, input1)
dataset = dataset.append (input1)

print(dataset)
print(validation)
print('Dataset %d, Validation %d' % (len(dataset), len(validation)))
dataset.to_csv('dataset.csv')
validation.to_csv('validation.csv')


# In[ ]:


dataset[1999:2000]


# In[ ]:




