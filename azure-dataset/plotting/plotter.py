#!/usr/bin/python

import sys
import csv
import io
import matplotlib.pyplot as plt
import argparse

# Syntax example: cat data.txt | plotter.py
# data.txt should be a file with four collumns.


def read_stdin_xy():
  # Read input from stdin.
  input = sys.stdin.read()

  # Read string as a csv file (line by line, separated by a delimiter).
  reader = csv.reader(io.StringIO(input), delimiter=' ')

  x = []
  yUsers = []
  yFunctions = []
  yInvocations = []

  # For each line, split and add to x and or y.
  for cols in reader:
    try:
      xentry = float(cols[0])
      usersEntry = float(cols[1])
      functionsEntry = float(cols[2])
      invocationsEntry = float(cols[3])
      x.append(xentry)
      yUsers.append(usersEntry)
      yFunctions.append(functionsEntry)
      yInvocations.append(invocationsEntry)
    except Exception as e:
      print("Warning ignoring " + str(cols))
  return x, yUsers, yFunctions, yInvocations


parser = argparse.ArgumentParser(description='Plot two-dimensional datapoints.')
parser.add_argument('-o', '--output', required=False)
parser.add_argument('-x', '--xlabel', required=False)
parser.add_argument('-y', '--ylabel', required=False)
parser.add_argument('-ymax', '--ymax', required=False)

args = parser.parse_args()

x, users, functions, invocations = read_stdin_xy()
first = x[0]
x = [elem - first for elem in x]

fig = plt.figure()
ax1 = fig.add_subplot(111)

ax1.scatter(x, users, s=1, label='Users')
ax1.scatter(x, functions, s=1, label='Functions')
ax1.scatter(x, invocations, s=1, label='Invocations')

plt.legend(loc='upper left')

# Plot.
plt.ylim(ymin=0)#, ymax=float(args.ymax))
plt.xlim(xmin=0)

if args.xlabel is not None:
  plt.xlabel(args.xlabel)

if args.ylabel is not None:
  plt.ylabel(args.ylabel)

if args.output is not None:
  plt.savefig(args.output)
else:
  plt.show()

