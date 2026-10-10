# 🌊 Water Surface Cleaning Robot Using Controller

A MATLAB-based simulation project for an intelligent **Water Surface Cleaning Robot** designed to collect floating waste from different aquatic environments. The project explores two approaches to water surface cleaning: **controller-based autonomous navigation** and **multi-robot autonomous cleaning**.

The controller-based version incorporates advanced control algorithms to improve robot movement, obstacle avoidance, target tracking, and navigation under environmental disturbances. The multi-robot version demonstrates systematic area coverage, coordination between robots, waste collection, and performance evaluation.

The project provides a simulation framework for studying intelligent water-cleaning robots before potential real-world implementation.

---

## 📌 Project Overview

Floating waste is a major environmental problem that affects lakes, rivers, ponds, swimming pools, and other aquatic environments. Manual waste collection can be time-consuming and inefficient, particularly across large water surfaces.

This project simulates water-cleaning robots that navigate a water environment, locate floating waste, avoid obstacles, and collect waste while adapting to changing conditions.

Two MATLAB implementations are included:

1. **WaterSurfaceCleaning_usingController.m** — an advanced autonomous control simulation using PID-based heading control, adaptive speed control, predictive obstacle avoidance, and intelligent navigation.
2. **WaterSurfaceCleaningRobot.m** — a multi-robot cleaning simulation featuring coverage path planning, configurable robot deployment, obstacle avoidance, and performance analysis.

Both implementations focus on simulated robot behavior rather than direct control of physical hardware.

---

## 🎯 Objectives

- Develop an intelligent water surface cleaning robot simulation.
- Implement controller-based navigation and movement regulation.
- Explore different aquatic environments with unique boundaries and obstacles.
- Detect and collect simulated floating waste.
- Improve navigation using obstacle avoidance and dynamic path planning.
- Coordinate multiple robots to improve cleaning efficiency.
- Simulate environmental disturbances such as wind, waves, and water currents.
- Evaluate robot performance using measurable simulation metrics.

---

## 🚀 Features

### 🌍 1. Multiple Water Environments

The simulation supports five environments:

- Lake
- Pond
- Swimming Pool
- River
- Ocean

Each environment has its own dimensions, water boundaries, obstacle configuration, waste distribution, and movement characteristics.

The simulation also models environmental disturbances according to the selected environment and disturbance level.

### 🎮 2. Controller-Based Autonomous Navigation

The controller-based implementation focuses on intelligent movement control rather than a physical handheld remote controller.

Its control system includes:

- PID-based heading control.
- Adaptive PID gain adjustment.
- Adaptive robot speed control.
- Target-directed navigation.
- Predictive obstacle avoidance.
- Predictive inter-robot collision avoidance.
- Dynamic path replanning.
- Stuck detection and recovery.
- Battery and energy management.
- Coverage monitoring.

These mechanisms help the simulated robot navigate toward targets while accounting for obstacles, boundaries, and environmental disturbances.

### 🤖 3. Multi-Robot Deployment

The multi-robot implementation supports up to **five autonomous robots**.

Features include:

- Configurable number of robots.
- User-defined robot speeds.
- Automatic waypoint distribution.
- Independent robot movement.
- Individual robot tracking.
- Coordinated cleaning activities.

This approach allows different robot configurations to be tested within the same simulated environment.

### 🧭 4. Coverage Path Planning

The multi-robot simulation uses a **lawnmower (boustrophedon) coverage pattern** to generate systematic cleaning waypoints.

The robots sweep across the water surface in alternating directions.

Benefits include:

- Systematic area coverage.
- Reduced unnecessary movement.
- Better distribution of cleaning tasks.
- More efficient use of robot travel distance.

### 🗑️ 5. Intelligent Waste Collection

The simulation generates floating waste at randomized positions within the water boundaries.

Waste items move according to simulated environmental conditions.

The simulation uses different visual markers and colors to represent waste items.

Supported conceptual waste categories include:

- Plastic
- Paper
- Metal
- Glass
- Organic waste
- Electronic waste

Waste collection is represented by detecting when a robot reaches a waste target and marking that item as collected.

### 🚧 6. Obstacle Avoidance

The simulation includes fixed and floating obstacles represented using different geometric shapes.

Examples include:

- Rocks
- Pillars
- Buoys
- Floating debris
- Moving obstacles

The controller-based implementation uses predictive obstacle avoidance and repulsive navigation forces to help the robot steer away from obstacles.

It also accounts for water boundaries and nearby robots when calculating safe movement.

### 🌬️ 7. Environmental Disturbance Simulation

The controller-based implementation models environmental effects, including:

- Wind and random gusts.
- Water currents.
- Wave-related movement.
- Small heading disturbances.

The disturbance level can be configured to represent different operating conditions.

These effects allow navigation and control algorithms to be evaluated under more challenging simulated conditions.

### 🤝 8. Multi-Robot Coordination

The multi-robot implementation distributes cleaning waypoints among deployed robots.

The controller-based implementation also incorporates mechanisms for dynamic task allocation and predictive collision avoidance between robots.

These techniques help reduce congestion and support more efficient task execution.

### 🔋 9. Energy Management and Recovery

The controller-based implementation includes simulated battery and energy management.

It tracks energy consumption associated with movement, turning, and environmental disturbances. Battery thresholds can influence the robot's decisions to return to base.

The simulation also includes stuck detection and recovery mechanisms to help robots escape situations where navigation progress is limited.

### 🏠 10. Autonomous Return to Base

Robots can return to a designated home base when their assigned cleaning tasks are complete.

The controller-based implementation also incorporates battery-related return behavior.

This functionality is simulated; it does not establish that a physical robot can autonomously dock or recharge.

### 📊 11. Performance Analytics

The project evaluates robot behavior using metrics such as:

- Waste collection progress over time.
- Robot travel distance.
- Total mission duration.
- Collection events.
- Waste distribution.
- Individual robot performance.
- Battery and energy behavior in the controller-based simulation.

These measurements help compare navigation strategies and robot configurations.

---

## 🏗️ System Architecture

### Controller-Based Autonomous Robot

```text
+---------------------------+
| Environment Configuration |
+-------------+-------------+
              |
              v
+---------------------------+
| Robot Initialization      |
+-------------+-------------+
              |
              v
+---------------------------+
| Target Selection          |
+-------------+-------------+
              |
              v
+---------------------------+
| Navigation Controller     |
| PID + Adaptive Speed      |
+-------------+-------------+
              |
              v
+---------------------------+
| Predictive Obstacle       |
| and Collision Avoidance   |
+-------------+-------------+
              |
              v
+---------------------------+
| Robot Movement Simulation |
+-------------+-------------+
              |
              v
+---------------------------+
| Waste Collection          |
+-------------+-------------+
              |
              v
+---------------------------+
| Energy and Progress Check |
+-------------+-------------+
              |
              v
+---------------------------+
| Replanning / Return Base  |
+---------------------------+
```

### Multi-Robot Cleaning System

```text
+---------------------------+
| User Configuration        |
+-------------+-------------+
              |
              v
+---------------------------+
| Environment Setup         |
+-------------+-------------+
              |
              v
+---------------------------+
| Coverage Path Planning    |
+-------------+-------------+
              |
              v
+---------------------------+
| Multi-Robot Deployment    |
+-------------+-------------+
              |
              v
+---------------------------+
| Navigation and Coordination|
+-------------+-------------+
              |
       +------+------+
       |             |
       v             v
+-------------+ +----------------+
| Waste       | | Obstacle       |
| Collection  | | Avoidance      |
+------+------+ +--------+-------+
       |                |
       +--------+-------+
                |
                v
+---------------------------+
| Return to Home Base       |
+-------------+-------------+
              |
              v
+---------------------------+
| Performance Analysis      |
+---------------------------+
```

---

## ⚙️ Algorithms Used

### 1. PID Heading Control

The controller-based implementation uses a PID controller to regulate the robot's heading toward a target direction.

The controller considers heading error and its accumulated and changing values to determine the appropriate turning response.

### 2. Adaptive PID Control

The controller adjusts selected PID gains according to navigation conditions, such as heading error, obstacle proximity, and robot speed.

This helps adapt movement control to different situations.

### 3. Adaptive Speed Control

The robot adjusts its speed according to factors such as turning angle, nearby obstacles, boundaries, and other robots.

Speed reduction near hazards helps improve simulated navigation safety.

### 4. Predictive Obstacle Avoidance

The navigation system estimates future obstacle positions over a prediction horizon and calculates avoidance responses before a potential collision occurs.

### 5. Artificial Potential Field Navigation

Artificial potential field (APF) navigation combines attractive forces toward the target with repulsive forces from obstacles and boundaries.

The resulting direction guides the robot toward its destination while discouraging unsafe paths.

### 6. Dynamic Task Allocation

The controller-based implementation periodically evaluates cleaning tasks and assigns targets to robots.

This allows the simulation to adapt task assignments as waste is collected and robot conditions change.

### 7. Stuck Detection and Recovery

The controller monitors robot movement and progress toward its target. When progress is insufficient, recovery behavior helps the robot escape difficult navigation situations.

### 8. Lawn­mower Coverage Planning

The multi-robot implementation generates alternating sweep paths across the water environment and divides waypoints among the deployed robots.

---

## 🖥️ Simulation Workflow

```text
Start MATLAB Program
          |
          v
Select Water Environment
          |
          v
Configure Robots and Speeds
          |
          v
Initialize Waste and Obstacles
          |
          v
Generate Cleaning Targets
          |
          v
Select or Assign Robot Tasks
          |
          v
Calculate Navigation Direction
          |
          v
Apply Controller and Avoidance
          |
          v
Move Robots and Update Environment
          |
          v
Collect Waste
          |
          v
Update Progress and Energy
          |
          v
More Tasks Remaining?
       /         \
     Yes          No
      |            |
      v            v
 Replan or      Return to
 Continue       Home Base
      |            |
      +------------+
           |
           v
 Generate Performance Results
           |
           v
          End
```

---

## 📈 Performance Metrics

| Metric | Description |
|---|---|
| Collection Efficiency | Percentage of simulated waste collected |
| Mission Duration | Time required to complete the cleaning task |
| Robot Distance | Distance traveled by each robot |
| Total Distance | Combined travel distance of the robots |
| Collection Events | Recorded waste collection events over time |
| Waste Distribution | Category-wise waste statistics, where implemented |
| Heading Control | Robot heading regulation during navigation |
| Obstacle Avoidance | Robot response to nearby and predicted obstacles |
| Energy Consumption | Simulated energy usage in the controller-based implementation |
| Battery Level | Estimated remaining battery in the controller-based implementation |

---

## ▶️ How to Run

### Prerequisites

- MATLAB.
- The relevant project `.m` file.
- MATLAB functions and dependencies used by the selected implementation.

### Option 1: Controller-Based Autonomous Simulation

1. Open MATLAB.
2. Open `WaterSurfaceCleaning_usingController.m`.
3. Run the script.
4. Select the environment and configure the available simulation settings.
5. Observe robot navigation, waste collection, obstacle avoidance, and control behavior.

Run the file using its name without the extension:

```matlab
WaterSurfaceCleaning_usingController
```

### Option 2: Multi-Robot Cleaning Simulation

1. Open MATLAB.
2. Open `WaterSurfaceCleaningRobot(2).m`.
3. Run the script.
4. Select the water environment.
5. Choose the number of robots, from one to five.
6. Assign the robot speeds.
7. Observe the cleaning simulation and performance results.

The second filename contains parentheses, so if MATLAB has trouble resolving it by its base name, rename the file to `WaterSurfaceCleaningRobot.m` and run:

```matlab
WaterSurfaceCleaningRobot
```

---

## 🔬 Future Enhancements

Potential extensions include:

- Integration with physical water-cleaning robot hardware.
- Wireless remote-control support.
- Real-time sensor integration.
- Computer vision for waste detection.
- GPS-based navigation where suitable.
- ROS integration.
- IoT-based monitoring.
- Reinforcement learning for navigation.
- Improved multi-robot task allocation.
- Energy-aware path planning.
- Real-world testing in controlled aquatic environments.

These are proposed extensions, not claims that the current MATLAB scripts already implement them.

---

## 🌱 Applications

- Floating waste collection research.
- Swimming pool surface cleaning.
- Pond and lake cleaning studies.
- River waste collection simulations.
- Autonomous robotics education.
- Multi-robot coordination research.
- Navigation and control algorithm testing.

---

## ⭐ Support

If you find this project useful:

- ⭐ Star the repository.
- 🍴 Fork the project.
- 📢 Share feedback and suggestions.
