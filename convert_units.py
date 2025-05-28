import csv

with open('units.csv') as unitsfile:
    with open('damage_matrix.csv') as matrixfile:
        with open("output.csv", "w") as outputfile:
            units = csv.reader(unitsfile, delimiter=',')
            matrix = csv.reader(matrixfile, delimiter=',')
            first_row = True
            column_keys = []
            output_table = {}
            for row in units:
                if first_row:
                    column_keys = row[1:]
                    first_row = False
                else:
                    unit = row[0]
                    index = 0
                    for column in row[1:]:
                        if unit not in output_table.keys():
                            output_table[unit] = {}
                        output_table[unit][column_keys[index]] = column
                        index += 1
            print(",", end='')
            print(",".join(column_keys), end='')
            outputfile.write(",")
            outputfile.write(",".join(column_keys))
            first_row = True
            for row in matrix:
                if first_row:
                    column_keys = row[1:]
                    first_row = False
                else:
                    unit = row[0]
                    index = 0
                    for column in row[1:]:
                        if unit not in output_table.keys():
                            output_table[unit] = {}
                        output_table[unit][column_keys[index]] = column
                        index += 1

            print("")
            outputfile.write("\n")
            for row in output_table.keys():
                print(f"{row},", end='')
                outputfile.write(f"{row},")
                for column in output_table[row].keys():
                    value = output_table[row][column]
                    print(f"{value},", end='')
                    outputfile.write(f"{value},")
                print("")
                outputfile.write("\n")