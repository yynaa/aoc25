import matplotlib.pyplot as plt

# Read coordinates from input.txt
coordinates = []
with open("input.txt", "r") as f:
    for line in f:
        line = line.strip()
        if line:
            # Extract coordinates from format "00001| 98162,50091"
            x, y = map(int, line.split(","))
            coordinates.append((x, y))

# Separate x and y coordinates
x_coords = [coord[0] for coord in coordinates]
y_coords = [coord[1] for coord in coordinates]

# Draw a rectangle from two of its corners
# Use first and last coordinates as opposite corners
corner1 = [5633, 67624]
corner2 = [94967, 50085]

# Create rectangle vertices
rect_x = [corner1[0], corner2[0], corner2[0], corner1[0], corner1[0]]
rect_y = [corner1[1], corner1[1], corner2[1], corner2[1], corner1[1]]

# Create canvas and draw line through all coordinates
plt.figure(figsize=(12, 8))
plt.plot(rect_x, rect_y, "r--", linewidth=2, label=f"Rectangle: {corner1} to {corner2}")
plt.plot(x_coords, y_coords, "b-", linewidth=2, marker="o", markersize=3)
plt.title("Line Through All Coordinates")
plt.xlabel("X Coordinate")
plt.ylabel("Y Coordinate")
plt.grid(True, alpha=0.3)
plt.axis("equal")

plt.show()
