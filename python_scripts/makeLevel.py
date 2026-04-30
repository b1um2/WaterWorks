levelName = "level2"

level = [
    3,    #valve count
    7,    #success water
    13, 6, #final tank top left corner

    6, 5, #valve pos
    6, 6, #valve tank pos
    3,    #tank water
    0,    #open or closed
    1,    #next valve
    0,    #final valve

    11, 7,#valve pos
    11, 6,#valve tank pos
    6,    #tank water
    0,    #open or closed
    0,    #next valve
    1,    #final valve

    9, 3,#valve pos
    10, 3,#valve tank pos
    1,    #tank water
    0,    #open or closed
    0,    #next valve
    0,    #final valve
]



with open(levelName+"_data.bin", "wb") as f:
    for i in level:
        f.write(i.to_bytes(4, "little"))