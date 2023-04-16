#!/usr/bin/python

import sys
import csv
import io
import matplotlib
import matplotlib.pyplot as plt

# Syntax example: cat plot-data.txt | plot-simulation.py
# data.txt should be a file with six columns.


def read_stdin_xy():
  # Read input from stdin.
  input = sys.stdin.read()

  # Read string as a csv file (line by line, separated by a delimiter).
  reader = csv.reader(io.StringIO(input), delimiter=' ')

  x = []
  yActiveUsers = []
  yActiveFunctions = []
  yCachedActiveUsers = []
  yCachedActiveFunctions = []
  yRunningInvocations = []

  # For each line, split and add to x and or y.
  for cols in reader:
    try:
      xentry = float(cols[0])
      activeUsersEntry = float(cols[1])
      activeFunctionsEntry = float(cols[2])
      cachedActiveUsersEntry = float(cols[3])
      cachedActiveFunctionsEntry = float(cols[4])
      runningInvocationsEntry = float(cols[5])
      x.append(xentry)
      yActiveUsers.append(activeUsersEntry)
      yActiveFunctions.append(activeFunctionsEntry)
      yCachedActiveUsers.append(cachedActiveUsersEntry)
      yCachedActiveFunctions.append(cachedActiveFunctionsEntry)
      yRunningInvocations.append(runningInvocationsEntry)
    except Exception as e:
      print("Warning ignoring " + str(cols))
  return x, yActiveUsers, yActiveFunctions, yCachedActiveUsers, yCachedActiveFunctions, yRunningInvocations


x, activeUsers, activeFunctions, cachedActiveUsers, cachedActiveFunctions, runningInvocations = read_stdin_xy()
first = x[0]
x = [elem - first for elem in x]

# Convert from ms to sec
x = [elem/1000 for elem in x]

matplotlib.rcParams.update({'font.size': 16})
plt.rcParams["figure.figsize"] = (10, 4)
#plt.rcParams["figure.figsize"] = (8, 5.5)
plt.xlabel('Time (seconds)')
plt.ylabel('# Functions, Users, Invocations')
plt.plot(x, activeFunctions,       linewidth=3, label='Active Functions')
plt.plot(x, activeUsers,           linewidth=3, label='Active Users')
plt.plot(x, runningInvocations,    linewidth=3, label='Invocations')
plt.plot(x, cachedActiveFunctions, linewidth=3, label='Cached Functions')
plt.plot(x, cachedActiveUsers,     linewidth=3, label='Cached Users')
plt.grid()
plt.yscale('log', base=10)
plt.ylim(ymin=0)
plt.xlim(xmin=0, xmax=600)
plt.legend(loc='lower left', ncol=2)
plt.savefig("azure-users-functions.pdf", bbox_inches='tight')
plt.savefig("azure-users-functions.png", bbox_inches='tight')
plt.show()
