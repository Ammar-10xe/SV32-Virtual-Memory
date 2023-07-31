import sys

with open("sail.log", 'r') as infile:
    lines = infile.readlines()

column = 67
file = []
for line in lines:
    if (line != "\n"):
        line = line.rstrip("\n")  # Remove newline character from the end of the line
        last = line[-1]
        line = line[:-2]
        while len(line) < column:
            line += " "
        if(last == "\\"):
            line += ";\\\n"
        else:
            line += ";\n"
        file.append(line)
    else:
        file.append("\n")

with open("sail.out", 'w') as outfile:
        outfile.writelines(file)