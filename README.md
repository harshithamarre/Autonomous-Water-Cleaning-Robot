# 🌊 Autonomous Multi-Robot Water Surface Cleaning System

An intelligent MATLAB-based simulation of an **Autonomous Multi-Robot Water Surface Cleaning System** designed to collect floating waste from various aquatic environments. The project demonstrates **coverage path planning, multi-robot coordination, obstacle avoidance, trash detection, and performance evaluation** in dynamic water environments such as lakes, rivers, ponds, pools, and oceans.

---

## 📌 Project Overview

Water pollution caused by floating waste is a major environmental challenge. Manual cleaning of large water bodies is time-consuming, expensive, and often inefficient.

This project simulates a fleet of autonomous cleaning robots capable of:

* Navigating different water environments.
* Detecting and collecting floating waste.
* Avoiding static and dynamic obstacles.
* Coordinating with multiple robots.
* Returning safely to the home base after mission completion.
* Generating performance statistics and analytical graphs.

The simulation provides a realistic framework for studying autonomous cleaning systems before real-world deployment.

---

## 🎯 Objectives

* Develop an autonomous water surface cleaning solution.
* Simulate multiple water environments with unique characteristics.
* Implement multi-robot coordination.
* Achieve efficient area coverage using systematic sweep patterns.
* Avoid collisions with obstacles and other robots.
* Evaluate mission efficiency through performance metrics.

---

## 🚀 Features

### 🌍 Multiple Water Environments

The simulation supports:

* Lake
* Pond
* Swimming Pool
* River
* Ocean

Each environment includes:

* Unique boundaries
* Different dimensions
* Distinct obstacle layouts
* Environment-specific trash movement behavior

---

### 🤖 Multi-Robot Deployment

* Deploy up to **5 autonomous robots**.
* User-defined robot speeds.
* Automatic workload distribution.
* Independent waypoint assignment.

---

### 🧭 Coverage Path Planning

The robots use a **lawnmower (boustrophedon) coverage pattern** to ensure systematic cleaning of the water surface.

Benefits:

* High area coverage
* Reduced overlap
* Efficient mission completion

---

### 🗑️ Intelligent Trash Collection

The system simulates floating waste with:

* Dynamic movement
* Multiple waste categories
* Randomized placement

Supported waste types:

* Plastic
* Paper
* Metal
* Glass
* Organic
* Electronic Waste

---

### 🚧 Obstacle Management

The simulation includes:

#### Fixed Obstacles

Examples:

* Rocks
* Pillars
* Buoys

#### Floating Obstacles

Examples:

* Driftwood
* Floating debris
* Moving barriers

Features:

* Collision avoidance
* Dynamic obstacle movement
* Safe navigation paths

---

### 🤝 Multi-Robot Coordination

Robots coordinate using:

* Path partitioning
* Inter-robot repulsion
* Collision prevention
* Independent task execution

This minimizes robot congestion and improves efficiency.

---

### 🏠 Autonomous Return-to-Base

After:

* Completing assigned waypoints
* Collecting remaining trash

Robots automatically return to the designated home base.

---

### 📊 Performance Analytics

The system generates:

* Distance traveled vs Time
* Trash collected vs Time
* Collection event timeline
* Waste-type distribution histogram

Mission statistics include:

* Collection efficiency
* Total mission duration
* Distance traveled by each robot
* Total distance traveled
* Number of obstacles
* Trash-type breakdown

---

## 🏗️ System Architecture

```text
+----------------------+
| User Configuration   |
+----------+-----------+
           |
           v
+----------------------+
| Environment Setup    |
+----------+-----------+
           |
           v
+----------------------+
| Coverage Path Plan   |
+----------+-----------+
           |
           v
+----------------------+
| Robot Deployment     |
+----------+-----------+
           |
           v
+----------------------+
| Navigation Module    |
+----------+-----------+
           |
           +----------------+
           |                |
           v                v
+----------------+   +------------------+
| Trash Detection|   |Obstacle Avoidance|
+----------------+   +------------------+
           |
           v
+----------------------+
| Collection Process   |
+----------+-----------+
           |
           v
+----------------------+
| Return To Base       |
+----------+-----------+
           |
           v
+----------------------+
| Performance Analysis |
+----------------------+
```

---

## ⚙️ Algorithms Used

### 1. Coverage Path Planning

A lawnmower sweep strategy is used to generate waypoints across the environment.

Advantages:

* Complete coverage
* Low computational cost
* Suitable for structured cleaning tasks

---

### 2. Obstacle Avoidance

Robots continuously check:

* Distance to nearby obstacles
* Future collision risks
* Boundary violations

The robot modifies its heading whenever an obstacle is detected within a safety radius.

---

### 3. Inter-Robot Collision Avoidance

A repulsive-force mechanism is used.

When robots become too close:

* Repulsion forces are generated.
* Navigation direction is adjusted.
* Collisions are avoided.

---

### 4. Target Pursuit

Robots move toward:

1. Detected trash.
2. Assigned waypoint.
3. Remaining uncollected trash.
4. Home base.

Priority-based decision making ensures mission completion.

---

## 🖥️ Simulation Workflow

```text
Start Simulation
        |
        v
Select Environment
        |
        v
Choose Number of Robots
        |
        v
Assign Robot Speeds
        |
        v
Generate Waypoints
        |
        v
Deploy Robots
        |
        v
Move Robots
        |
        +---- Detect Trash
        |
        +---- Avoid Obstacles
        |
        +---- Avoid Other Robots
        |
        v
Collect Waste
        |
        v
All Trash Collected?
      /   \
    No     Yes
    |        |
    |        v
    |   Return Home
    |        |
    +--------+
             |
             v
      Generate Statistics
             |
             v
            End
```

---

## 📈 Performance Metrics

The simulation evaluates:

| Metric                | Description                     |
| --------------------- | ------------------------------- |
| Collection Efficiency | Percentage of waste collected   |
| Mission Time          | Total time required             |
| Robot Distance        | Distance traveled by each robot |
| Total Distance        | Combined robot travel distance  |
| Collection Events     | Waste collection timeline       |
| Waste Distribution    | Category-wise collected waste   |

---

## ▶️ How to Run

### Step 1

Clone the repository:

```bash
git clone https://github.com/yourusername/Autonomous-Water-Surface-Cleaning-System.git
```

### Step 2

Open MATLAB.

### Step 3

Open:

```text
WaterSurfaceCleaningRobot.m
```

### Step 4

Run:

```matlab
WaterSurfaceCleaningRobot
```

### Step 5

Select:

* Environment
* Number of robots
* Robot speeds

The simulation will start automatically.

---

## 🔬 Future Enhancements

Potential improvements include:

* A* path planning
* Dijkstra-based navigation
* Reinforcement Learning
* Swarm Intelligence
* Real-time sensor integration
* ROS integration
* IoT-enabled monitoring
* Computer Vision based trash detection
* GPS-based navigation
* Energy-aware path planning
* Real-world robotic prototype

---

## ⭐ Support

If you found this project useful:

⭐ Star the repository

🍴 Fork the project

📢 Share your feedback

---

### “Clean Water Through Intelligent Automation.”
