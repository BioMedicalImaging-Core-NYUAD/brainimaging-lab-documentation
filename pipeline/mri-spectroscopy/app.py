import streamlit as st
import numpy as np
import matplotlib.pyplot as plt
from manim import *
import os
import tempfile

st.title("Cellular Automata Visualizer")

# Sidebar controls
st.sidebar.header("Simulation Parameters")
rule = st.sidebar.selectbox("Select Rule", ["Rule 30", "Rule 90", "Rule 110"])
size = st.sidebar.slider("Grid Size", 50, 200, 100)
steps = st.sidebar.slider("Number of Steps", 50, 500, 100)
initial_condition = st.sidebar.radio("Initial Condition", ["Single Cell", "Random"])

def create_initial_grid(size, initial_condition):
    grid = np.zeros((size, size), dtype=int)
    if initial_condition == "Single Cell":
        grid[0, size//2] = 1
    else:  # Random
        grid[0] = np.random.randint(0, 2, size)
    return grid

def apply_rule(grid, rule, step):
    new_grid = grid.copy()
    for i in range(1, grid.shape[1]-1):
        left = grid[step-1, i-1]
        center = grid[step-1, i]
        right = grid[step-1, i+1]
        
        if rule == "Rule 30":
            new_grid[step, i] = left ^ (center | right)
        elif rule == "Rule 90":
            new_grid[step, i] = left ^ right
        elif rule == "Rule 110":
            new_grid[step, i] = (center & right) | (center & ~left) | (right & ~left)
    
    return new_grid

def run_simulation():
    grid = create_initial_grid(size, initial_condition)
    for step in range(1, steps):
        grid = apply_rule(grid, rule, step)
    return grid

# Run simulation
if st.button("Run Simulation"):
    with st.spinner("Running simulation..."):
        grid = run_simulation()
        
        # Create visualization
        fig, ax = plt.subplots(figsize=(10, 10))
        ax.imshow(grid, cmap='binary')
        ax.axis('off')
        
        # Save the plot
        temp_dir = tempfile.mkdtemp()
        plot_path = os.path.join(temp_dir, "plot.png")
        plt.savefig(plot_path, bbox_inches='tight', pad_inches=0)
        plt.close()
        
        # Display the plot
        st.image(plot_path, use_column_width=True)
        
        # Create Manim animation
        class CellularAutomata(Scene):
            def construct(self):
                # Convert grid to Manim objects
                squares = VGroup()
                for i in range(grid.shape[0]):
                    for j in range(grid.shape[1]):
                        if grid[i, j] == 1:
                            square = Square(side_length=0.1, fill_opacity=1, color=WHITE)
                            square.move_to([j*0.1 - grid.shape[1]*0.05, -i*0.1 + grid.shape[0]*0.05, 0])
                            squares.add(square)
                
                self.play(Create(squares))
                self.wait(2)
        
        # Render Manim animation
        config.media_dir = temp_dir
        scene = CellularAutomata()
        scene.render()
        
        # Display the animation
        st.video(os.path.join(temp_dir, "CellularAutomata.mp4"))

# Add some documentation
st.markdown("""
## About Cellular Automata
Cellular automata are discrete models that consist of a grid of cells, each in one of a finite number of states. 
The grid can be in any finite number of dimensions. For each cell, a set of cells called its neighborhood is defined relative to the specified cell.

### Rules
- **Rule 30**: A rule that produces chaotic behavior
- **Rule 90**: A rule that produces a Sierpinski triangle pattern
- **Rule 110**: A rule that is Turing complete
""") 