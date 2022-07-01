import json

data = []

with open('temp/pc_simulation.log', 'r') as f:
    for i in f.readlines():
        j = i.split()
        name = j[0]
        ty = j[1]
        t = int(j[2])
        data.append({
            "name": name,
            "type": ty,
            "time": t
        })

with open('temp/load.json', 'w') as f:
    json.dump(data, f)