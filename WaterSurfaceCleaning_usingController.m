%% ---------------- LAUNCHER INTERFACE: ALL USER INPUT ----------------
% One control window replaces the old listdlg / inputdlg / questdlg
% pop-ups. It returns the same values those dialogs used to produce.

env_options = {'Lake', 'Pond', 'Pool', 'River', 'Ocean'};

cfg = launch_config_ui();

env_name   = cfg.env_name;
env_choice = find(strcmp(env_options, env_name));
fprintf('Environment selected: %s\n', env_name);

% ---- heading-controller selection (from launcher) ----
ctrl_names   = {'Adaptive PID','Fixed-gain PID','PD','Sliding-mode'};
ctrl_primary = cfg.controller;
compare_mode = cfg.compare;
if compare_mode
    run_list = [ctrl_primary, setdiff(1:4, ctrl_primary)];
else
    run_list = ctrl_primary;
end
SEED     = 1;                       % identical random world for every controller
cmp_runs = cell(1,numel(run_list));
fprintf('Heading controller: %s%s\n', ctrl_names{ctrl_primary}, ...
    ternary_str(compare_mode,' (comparing all controllers)',''));

%% ---------------- ENVIRONMENT PARAMETERS ----------------

switch env_name

    case 'Lake'
        xlim_range  = [0 120];
        ylim_range  = [0 80];
        water_color = [0.4 0.72 0.95];
        bg_color    = [0.6 0.85 1.0];
        boundary    = [0 0; 120 0; 110 55; 80 72; 40 75; 10 60; 0 30];
        spacing     = 7;
        xmin=8;  xmax=105; ymin=8;  ymax=65;
        num_trash   = 25;
        home_base   = [20 15];
        trash_speed_scale = 0.3;
        env_desc    = 'Large irregular natural lake';
        sweep_axis  = 'vertical';
        % obstacle_float_flags: 1 = floating, 0 = fixed
        % Expanded to 10 obstacles — 3 floating, 7 fixed
        obstacle_float_flags = [1; 0; 0; 1; 0; 0; 1; 0; 0; 0];
        obstacle_speed_scale = 0.002;

    case 'Pond'
        xlim_range  = [0 60];
        ylim_range  = [0 60];
        water_color = [0.3 0.65 0.45];
        bg_color    = [0.55 0.80 0.65];
        theta_pts   = linspace(0, 2*pi, 16)';
        cx=30; cy=30; rx=25; ry=22;
        bx = cx + rx*cos(theta_pts);
        by = cy + ry*sin(theta_pts);
        boundary    = [bx by];
        spacing     = 5;
        xmin=10; xmax=52; ymin=10; ymax=50;
        num_trash   = 12;
        home_base   = [15 15];
        trash_speed_scale = 0.15;
        env_desc    = 'Small compact pond';
        sweep_axis  = 'vertical';
        % 10 obstacles — 3 floating, 7 fixed
        obstacle_float_flags = [1; 0; 0; 1; 0; 0; 1; 0; 0; 0];
        obstacle_speed_scale = 0.65;

    case 'Pool'
        xlim_range  = [0 80];
        ylim_range  = [0 40];
        water_color = [0.1 0.65 0.85];
        bg_color    = [0.7 0.90 0.98];
        boundary    = [5 5; 75 5; 75 35; 5 35];
        spacing     = 5;
        xmin=8;  xmax=72; ymin=8;  ymax=32;
        num_trash   = 15;
        home_base   = [8 8];
        trash_speed_scale = 0.10;
        env_desc    = 'Rectangular swimming pool';
        sweep_axis  = 'vertical';
        % 9 obstacles — 4 floating, 5 fixed
        obstacle_float_flags = [1; 1; 0; 0; 1; 0; 0; 1; 0];
        obstacle_speed_scale = 1.038;

    case 'River'
        xlim_range  = [0 180];
        ylim_range  = [0 40];
        water_color = [0.3 0.55 0.80];
        bg_color    = [0.55 0.75 0.90];

        top_bank_x  = [0   30  60  90  120  150  180];
        top_bank_y  = [30  32  28  33   27   31   30];
        bot_bank_x  = [0   30  60  90  120  150  180];
        bot_bank_y  = [10  12   8  13    7   11   10];

        bx = [top_bank_x,  fliplr(bot_bank_x)];
        by = [top_bank_y,  fliplr(bot_bank_y)];
        boundary = [bx(:) by(:)];

        spacing    = 4;
        xmin = 5;   xmax = 173;
        ymin = 10;  ymax = 30;

        num_trash   = 30;
        home_base   = [10 20];
        trash_speed_scale = 0.5;
        env_desc    = 'Long narrow river channel';
        sweep_axis  = 'horizontal';
        % 7 obstacles for river (narrower space) — 3 floating, 4 fixed
        obstacle_float_flags = [1; 0; 1; 1; 0; 0; 0];
        obstacle_speed_scale = 1.35;

    case 'Ocean'
        xlim_range  = [0 200];
        ylim_range  = [0 120];
        water_color = [0.05 0.35 0.75];
        bg_color    = [0.2  0.55 0.90];
        bx = [0 200 200 0];
        by = [0 0   110 110];
        boundary    = [bx' by'];
        spacing     = 10;
        xmin=10; xmax=185; ymin=10; ymax=100;
        num_trash   = 40;
        home_base   = [15 15];
        trash_speed_scale = 0.6;
        env_desc    = 'Open ocean surface';
        sweep_axis  = 'vertical';
        % 8 obstacles — 3 floating, 5 fixed
        obstacle_float_flags = [1; 0; 0; 1; 0; 0; 1; 0];
        obstacle_speed_scale = 0.9;
end

%% ---------------- ROBOTS: COUNT AND SPEEDS (from launcher) ----------------

num_robots_total = cfg.num_robots;
fprintf('Deploying %d robot(s)...\n', num_robots_total);

robot_speeds = cfg.speeds(1:num_robots_total);
robot_speeds = max(1, min(10, robot_speeds));

fprintf('\nRobot speeds assigned:\n');
for r = 1:num_robots_total
    fprintf('  Robot %d: %.1f units/s\n', r, robot_speeds(r));
end

%% ---------------- ENVIRONMENTAL DISTURBANCES ----------------
% Three disturbance sources act on the robots (and, more weakly, on the
% floating trash):
%   WIND     steady base + random gusts (Ornstein-Uhlenbeck process)
%   CURRENT  steady flow (the River also has a mid-channel speed profile)
%   WAVES    sinusoidal sideways push, plus small random yaw jitter
% dist_scale multiplies all of them (0 = off, 1 = moderate, 2 = severe).

dist_choice = cfg.dist_choice;

switch dist_choice
    case 'Off'
        dist_scale = 0;
    case 'Moderate'
        dist_scale = 1;
    otherwise
        dist_scale = 2;
end
fprintf('Disturbance level: %s (scale %.1f)\n', dist_choice, dist_scale);

% Base values are velocities in the same units/s as the robot speeds.
switch env_name
    case 'Lake'
        wind_base = [0.5 0.2];  gust_sigma = 0.40;  gust_tau = 4.0;
        current_base = [0.05 0];
        wave_amp = 0.15;  wave_freq = 0.25;  yaw_sigma = 0.05;
    case 'Pond'
        wind_base = [0.2 0.1];  gust_sigma = 0.20;  gust_tau = 4.0;
        current_base = [0 0];
        wave_amp = 0.05;  wave_freq = 0.30;  yaw_sigma = 0.03;
    case 'Pool'
        wind_base = [0.1 0.05]; gust_sigma = 0.05;  gust_tau = 4.0;
        current_base = [0 0];
        wave_amp = 0.08;  wave_freq = 0.40;  yaw_sigma = 0.02;
    case 'River'
        wind_base = [0.3 0];    gust_sigma = 0.30;  gust_tau = 3.0;
        current_base = [0.6 0];
        wave_amp = 0.05;  wave_freq = 0.30;  yaw_sigma = 0.04;
    case 'Ocean'
        wind_base = [1.2 0.6];  gust_sigma = 0.80;  gust_tau = 5.0;
        current_base = [0.4 0.2];
        wave_amp = 0.50;  wave_freq = 0.20;  yaw_sigma = 0.10;
end

windage        = 0.5;   % fraction of wind speed that actually pushes a robot
trash_coupling = 0.4;   % fraction of the disturbance that also moves trash
wind_gust      = [0 0]; % current gust state (evolves in the main loop)

%% ---------------- ROBOT COLORS ----------------

robot_colors = [
    1.0  0.0  0.0;
    0.0  0.7  0.0;
    0.0  0.1  1.0;
    1.0  0.5  0.0;
    0.6  0.0  0.8;
];

%% ================================================================
%  RUN LOOP: one full mission per controller.
%  Normal mode runs just the selected controller. Compare mode re-runs
%  the SAME world (same seed -> same trash, obstacles, wind gusts, yaw
%  noise) once per controller so the results are directly comparable.
%  ================================================================

for run_k = 1:numel(run_list)

ctrl_id   = run_list(run_k);
ctrl_name = ctrl_names{ctrl_id};
fprintf('\n##### RUN %d/%d : heading controller = %s #####\n', ...
    run_k, numel(run_list), ctrl_name);

rng(SEED);
rs_gust   = RandStream('mt19937ar','Seed',SEED+1);   % wind-gust noise
rs_yaw    = RandStream('mt19937ar','Seed',SEED+2);   % wave yaw jitter
wind_gust = [0 0];
is_detail = (~compare_mode) || (ctrl_id == ctrl_primary);

%% ---------------- FIGURE & ENVIRONMENT DRAWING ----------------

figure('Color','white','Name','Live Simulation - Autonomous Water Surface Cleaning','NumberTitle','off');
try, set(gcf,'WindowState','maximized'); catch, end
live_fig = gcf;
hold on;
axis equal;
xlim(xlim_range);
ylim(ylim_range);

rectangle('Position',[xlim_range(1) ylim_range(1) ...
    diff(xlim_range) diff(ylim_range)], ...
    'FaceColor', bg_color, 'EdgeColor','none');

title(sprintf('Autonomous Water Surface Cleaning (%d robot(s)) — %s', ...
    num_robots_total, [env_name ' | ' ctrl_name]));
xlabel('X Position');
ylabel('Y Position');

water_patch = fill(boundary(:,1), boundary(:,2), water_color, 'FaceAlpha', 0.45);
plot(boundary(:,1), boundary(:,2), 'b', 'LineWidth', 2);

annotation_x = xlim_range(1) + 0.55*diff(xlim_range);
annotation_y = ylim_range(2) - 0.07*diff(ylim_range);
label_text = sprintf('[%s] %s', char(env_name), char(env_desc));
text(annotation_x, annotation_y, label_text, ...
    'FontSize', 9, 'Color', [0.1 0.1 0.5], ...
    'BackgroundColor', [0.95 0.95 1], 'Margin', 5);

plot(home_base(1), home_base(2), 'kp', 'MarkerSize',12, 'MarkerFaceColor','y');
text(home_base(1)+1.5, home_base(2)+1.5, 'Home', 'FontSize', 9);

%% ---------------- ENVIRONMENT VISUALS (waves, water flow, wind) ----------------
% Everything here is drawn as animated graphics objects that are updated
% every frame inside the main loop:
%   1. WAVE RIPPLES   - broken crest lines travelling downwind across the water
%   2. WATER FLOW     - floating foam/debris particles with streak tails,
%                       advected by the real current + wind field
%   3. WIND STREAKS   - gust lines racing across the whole scene
%   4. BOBBING        - robots and trash heave up/down on the waves
%   5. SURFACE SHADE  - water darkens as the wind picks up
% All of them are hidden when the disturbance level is "Off".

W_v = diff(xlim_range);
H_v = diff(ylim_range);
vis_on = dist_scale > 0;

% ---- 1. wave ripples ----
wave_len  = 0.08*W_v;                          % wavelength
wave_D    = hypot(W_v,H_v);
wave_cx   = mean(xlim_range);
wave_cy   = mean(ylim_range);
wave_nJ   = ceil(wave_D/wave_len) + 2;         % number of crest lines
wave_M    = 70;                                % points per crest line
wave_u    = linspace(-wave_D/2, wave_D/2, wave_M)';        % along-crest coord
wave_j    = -floor(wave_nJ/2) : ceil(wave_nJ/2)-1;         % crest indices
if norm(wind_base) > 1e-6
    wave_ang = atan2(wind_base(2), wind_base(1));
else
    wave_ang = 0;
end
wave_off  = 0;
% static dash mask so crests look like broken ripples, not full lines
wave_mask = sin(2*pi*wave_u/(2.2*wave_len) + 1.7*wave_j) > -0.25;
wave_line = plot(NaN,NaN,'-','Color',[1 1 1],'LineWidth',1.2);

% ---- 2. water-flow particles ----
n_flow        = 220;
flow_pos      = spawn_in_poly(n_flow, boundary, xlim_range, ylim_range);
flow_life     = 8 + 12*rand(n_flow,1);
flow_age      = flow_life .* rand(n_flow,1);
flow_gain     = 0.07*W_v;       % visual speed-up so slow currents are visible
flow_tail_max = 0.06*W_v;
flow_line = plot(NaN,NaN,'-','Color',[0.85 0.95 1],'LineWidth',1.3);
flow_dots = plot(NaN,NaN,'.','Color',[1 1 1],'MarkerSize',8);

% ---- 3. wind streaks ----
n_wind      = 40;
wind_pos    = [xlim_range(1)+W_v*rand(n_wind,1), ylim_range(1)+H_v*rand(n_wind,1)];
wind_gain   = 0.12*W_v;
wind_streak = plot(NaN,NaN,'-','Color',[0.30 0.45 0.55],'LineWidth',0.8);

if ~vis_on
    set([wave_line flow_line flow_dots wind_streak],'Visible','off');
end

%% ---------------- GLOBAL COVERAGE PATH ----------------
% NOTE: the waypoints are still generated (coverage tasks use them), but
% the magenta dashed waypoint path is no longer drawn on the figure.

all_waypoints = [];
W = diff(xlim_range);
H = diff(ylim_range);

if strcmp(sweep_axis, 'horizontal')
    y_lines   = ymin:spacing:ymax;
    x_sample  = linspace(xlim_range(1), xlim_range(2), 4000);

    for i = 1:length(y_lines)
        yi = y_lines(i);
        inside_mask = inpolygon(x_sample, repmat(yi, size(x_sample)), ...
                                boundary(:,1), boundary(:,2));
        if ~any(inside_mask), continue; end
        x_inside = x_sample(inside_mask);
        x_lo = max(min(x_inside), xmin);
        x_hi = min(max(x_inside), xmax);
        if x_hi <= x_lo, continue; end
        if mod(i,2)==1
            all_waypoints = [all_waypoints; x_lo yi; x_hi yi]; %#ok<AGROW>
        else
            all_waypoints = [all_waypoints; x_hi yi; x_lo yi]; %#ok<AGROW>
        end
    end
else
    x_lines  = xmin:spacing:xmax;
    y_sample = linspace(ylim_range(1), ylim_range(2), 2000);

    for i = 1:length(x_lines)
        xi = x_lines(i);
        inside_mask = inpolygon(repmat(xi, size(y_sample)), y_sample, ...
                                boundary(:,1), boundary(:,2));
        if ~any(inside_mask), continue; end
        y_inside = y_sample(inside_mask);
        y_lo = max(min(y_inside), ymin);
        y_hi = min(max(y_inside), ymax);
        if y_hi <= y_lo, continue; end
        if mod(i,2)==1
            all_waypoints = [all_waypoints; xi y_lo; xi y_hi]; %#ok<AGROW>
        else
            all_waypoints = [all_waypoints; xi y_hi; xi y_lo]; %#ok<AGROW>
        end
    end
end

%% ---------------- OBSTACLES ----------------
% Columns: [cx_frac, cy_frac, shape_type, size_frac_x, size_frac_y]
% shape_type: 1=circle, 2=rectangle, 3=triangle
% Sizes are fractions of W (x) and H (y).
%
% Each environment now has ~10 obstacles spread across the water body.
% Fixed obstacles are distributed to create navigational challenges without
% completely blocking the sweep paths.

ox = xlim_range(1); oy = ylim_range(1);

switch env_name

    case 'Lake'
        % 10 obstacles spread across the irregular lake
        obs_fracs = [
            0.48  0.60  1  0.028  0;      % centre-left, circle
            0.35  0.38  2  0.032  0.042;  % mid-left, rectangle
            0.60  0.52  3  0.022  0;      % centre, triangle
            0.72  0.35  1  0.020  0;      % right-mid, circle
            0.18  0.55  2  0.025  0.033;  % left, rectangle
            0.55  0.75  1  0.018  0;      % upper-centre, circle  (NEW)
            0.80  0.60  2  0.022  0.030;  % upper-right, rectangle (NEW)
            0.30  0.70  3  0.020  0;      % upper-left, triangle  (NEW)
            0.65  0.20  1  0.022  0;      % lower-right, circle   (NEW)
            0.42  0.45  2  0.018  0.025;  % centre, small rect    (NEW)
        ];

    case 'Pond'
        % 9 obstacles inside the elliptical pond — kept well within boundary
        obs_fracs = [
            0.50  0.55  1  0.025  0;
            0.35  0.42  2  0.028  0.035;
            0.62  0.48  3  0.022  0;
            0.50  0.35  1  0.020  0;
            0.40  0.60  2  0.022  0.030;
            0.60  0.62  1  0.018  0;
            0.45  0.50  3  0.020  0;
            0.55  0.40  2  0.018  0.025;
            0.38  0.55  1  0.016  0;
        ];

    case 'Pool'
        % 10 obstacles in the rectangular pool — arranged in two rows
        obs_fracs = [
            0.25  0.45  1  0.022  0;
            0.40  0.65  2  0.025  0.030;
            0.55  0.35  1  0.020  0;
            0.70  0.60  3  0.022  0;
            0.85  0.40  2  0.020  0.028;
            0.30  0.70  1  0.018  0;
            0.50  0.55  2  0.022  0.025;
            0.65  0.45  1  0.020  0;
            0.75  0.30  3  0.018  0;
            0.45  0.35  1  0.016  0;
        ];

    case 'River'
        % 7 obstacles spread along the river channel (narrower environment)
        river_chan_w = xmax - xmin;
        river_chan_h = ymax - ymin;
        obs_fracs = [
            0.12  0.55  1  0.020  0;      % near-inlet, circle
            0.25  0.30  2  0.016  0.20;   % upper-quarter, rectangle
            0.38  0.70  1  0.018  0;      % lower-third, circle
            0.50  0.45  3  0.020  0;      % midpoint, triangle
            0.62  0.60  2  0.015  0.18;   % three-quarter, rectangle (NEW)
            0.74  0.35  1  0.018  0;      % three-quarter low, circle(NEW)
            0.85  0.65  3  0.016  0;      % near-exit upper, triangle(NEW)
        ];

    case 'Ocean'
        % 8 obstacles spread across the large ocean grid
        obs_fracs = [
            0.48  0.60  1  0.028  0;
            0.35  0.38  2  0.032  0.042;
            0.60  0.52  3  0.022  0;
            0.72  0.35  1  0.020  0;
            0.18  0.55  2  0.025  0.033;
            0.55  0.75  1  0.020  0;
            0.80  0.65  2  0.024  0.035;
            0.25  0.75  3  0.022  0;
        ];
end

% Convert fractional coords to absolute coords
num_obstacles = size(obs_fracs, 1);
obstacles = obs_fracs;

if strcmp(env_name, 'River')
    river_chan_w = xmax - xmin;
    river_chan_h = ymax - ymin;
    obstacles(:,1) = xmin + obs_fracs(:,1) * river_chan_w;
    obstacles(:,2) = ymin + obs_fracs(:,2) * river_chan_h;
    obstacles(:,4) = obs_fracs(:,4) * river_chan_w;
    obstacles(:,5) = obs_fracs(:,5) * river_chan_h;
else
    obstacles(:,1) = ox + obs_fracs(:,1)*W;
    obstacles(:,2) = oy + obs_fracs(:,2)*H;
    obstacles(:,4) = obs_fracs(:,4)*W;
    obstacles(:,5) = obs_fracs(:,5)*H;
end

%% ---- FLOATING OBSTACLE VELOCITIES ----------------

% Pad/trim flags to match actual num_obstacles
if length(obstacle_float_flags) < num_obstacles
    obstacle_float_flags(end+1:num_obstacles) = 0;
else
    obstacle_float_flags = obstacle_float_flags(1:num_obstacles);
end

obs_velocity = zeros(num_obstacles, 2);
for k = 1:num_obstacles
    if obstacle_float_flags(k)
        angle_k = 2*pi*rand();
        speed_k = obstacle_speed_scale * (1 + 0.5*rand());
        obs_velocity(k,:) = speed_k * [cos(angle_k), sin(angle_k)];
    end
end

%% ---- DRAW INITIAL OBSTACLES & STORE HANDLES ----------------

obs_handles = cell(num_obstacles, 1);

for i = 1:num_obstacles
    obs = obstacles(i,:);
    switch obs(3)
        case 1
            theta = linspace(0,2*pi,50);
            obs_handles{i} = fill(obs(1)+obs(4)*cos(theta), obs(2)+obs(4)*sin(theta), ...
                [0.4 0.4 0.4],'FaceAlpha',0.6,'EdgeColor','k','LineWidth',2);
        case 2
            s4=obs(4); s5=max(obs(5),obs(4)*0.6);
            obs_handles{i} = fill([obs(1)-s4 obs(1)+s4 obs(1)+s4 obs(1)-s4], ...
                 [obs(2)-s5 obs(2)-s5 obs(2)+s5 obs(2)+s5], ...
                 [0.5 0.3 0.3],'FaceAlpha',0.6,'EdgeColor','k','LineWidth',2);
        case 3
            obs_handles{i} = fill([obs(1) obs(1)+obs(4) obs(1)-obs(4)], ...
                 [obs(2)+obs(4) obs(2)-obs(4)/2 obs(2)-obs(4)/2], ...
                 [0.3 0.5 0.3],'FaceAlpha',0.6,'EdgeColor','k','LineWidth',2);
    end
    % Mark floating obstacles with a dashed edge
    if obstacle_float_flags(i)
        set(obs_handles{i}, 'LineStyle', '--', 'EdgeColor', [0.8 0.5 0]);
    end
end

%% ---------------- TRASH ----------------

trash_colors_palette = [
    0 0.8 0; 0.8 0.8 0; 0.8 0.4 0; 0.6 0.2 0.8; 1 0.5 0; 0 0.8 0.8;
];
trash_markers = {'o','s','d','^','v','pentagram'};
trash_color_idx  = randi(size(trash_colors_palette,1), num_trash, 1);
colored_trash    = trash_colors_palette(trash_color_idx, :);
trash_marker_idx = randi(length(trash_markers), num_trash, 1);
collected        = zeros(num_trash, 1);
trash            = zeros(num_trash, 2);

% Minimum distance a piece of trash must sit from the ACTUAL shoreline
% polygon (not just the outer bounding rectangle). Irregular water
% bodies (Lake/Pond/River) can have shoreline that cuts much closer to
% the interior than the rectangle-based spawn band below assumes.
% Pushed up further here so trash simply never spawns anywhere near the
% boundary in the first place, rather than relying on the robot being
% able to reach right up to the edge.
boundary_margin = max(8, spacing*1.5);

for i = 1:num_trash
    inside = false; too_close = true;
    attempt = 0;

    while (~inside || too_close) && attempt < 8000
        attempt = attempt + 1;
        if strcmp(env_name, 'River')
            tx = xmin + (xmax-xmin)*rand();
            ty = ymin + (ymax-ymin)*rand();
        else
            tx = xlim_range(1)+0.1*W + 0.8*W*rand();
            ty = ylim_range(1)+0.1*H + 0.8*H*rand();
        end
        test_point = [tx ty];
        inside = inpolygon(test_point(1), test_point(2), ...
                           boundary(:,1), boundary(:,2));

        if inside
            % Reject points that are technically inside the polygon
            % but sit right on top of the shoreline edge -- those were
            % the ones robots could approach but never quite reach.
            edge_dist = distance_to_polygon_boundary(tx, ty, boundary);
            if edge_dist < boundary_margin
                inside = false;
            end
        end

        if inside
            too_close = false;
            for k = 1:num_obstacles
                obs = obstacles(k,:);
                dist_to_obs = norm(test_point - obs(1:2));
                if obs(3)==1, sm=obs(4)+3;
                elseif obs(3)==2, sm=max(obs(4),obs(5))+3;
                else, sm=obs(4)+3; end
                if dist_to_obs < sm, too_close=true; break; end
            end
        end
    end
    trash(i,:) = test_point;
end

trash_plot = gobjects(num_trash, 1);
for i = 1:num_trash
    trash_plot(i) = scatter(trash(i,1), trash(i,2), 80, ...
        colored_trash(i,:), trash_markers{trash_marker_idx(i)}, 'filled');
end

trash_velocity = trash_speed_scale * (0.5 + rand(num_trash,2)) .* ...
    (2*randi([0,1],num_trash,2)-1);

if strcmp(env_name, 'River')
    trash_velocity(:,1) = trash_speed_scale * (0.5 + 0.5*rand(num_trash,1));
    trash_velocity(:,2) = 0.15 * trash_speed_scale * (2*rand(num_trash,1)-1);
end


%% ================================================================
%  ADVANCED AUTONOMOUS ROBOT CONTROL SYSTEM
%
%  Clearly separated advanced features:
%    1. DYNAMIC TASK ALLOCATION
%    2. ADAPTIVE-GAIN PID HEADING CONTROL
%    3. ADAPTIVE SPEED CONTROL
%    4. PREDICTIVE OBSTACLE AVOIDANCE
%    5. PREDICTIVE INTER-ROBOT COLLISION AVOIDANCE
%    6. ARTIFICIAL POTENTIAL FIELD (APF) NAVIGATION
%    7. BATTERY / ENERGY MANAGEMENT
%    8. STUCK DETECTION AND RECOVERY
%    9. DYNAMIC REPLANNING
%   10. COVERAGE MONITORING
%   11. ENVIRONMENTAL DISTURBANCES (wind, current, waves)
%   12. SELECTABLE / COMPARABLE HEADING CONTROLLERS (adaptive PID, fixed PID, PD, sliding-mode)
%  ================================================================

%% ---------------- ADVANCED CONTROL PARAMETERS ----------------

dt = 0.10;

% ---------- PID HEADING CONTROLLER (base gains) ----------
Kp_heading = 2.80;
Ki_heading = 0.12;
Kd_heading = 0.65;

integral_limit = 1.50;
max_omega      = 2.50;

% ---------- ADAPTIVE PID GAIN SCHEDULING ----------
Kp_min = 1.50;  Kp_max = 5.00;
Kd_min = 0.40;  Kd_max = 0.95;
stab_margin = 0.95;       % keep Kd below 95% of the sampled-loop stability limit
adapt_err_gain   = 1.0;   % Kp boost for large heading errors
adapt_obs_boost  = 0.6;   % Kp/Kd boost when close to an obstacle
adapt_speed_damp = 0.8;   % extra Kd (damping) at high speed
adapt_dist_boost = 1.5;   % extra Ki to reject steady disturbances (wind/current)

% ---------- COMPARISON CONTROLLERS ----------
% ctrl_id 1 = Adaptive PID (gains scheduled online)
% ctrl_id 2 = Fixed-gain PID (Kp/Ki/Kd_heading, no scheduling)
% ctrl_id 3 = PD (fixed Kp/Kd, no integral)
% ctrl_id 4 = Sliding-mode: omega = smc_K*tanh(s/smc_phi), s = e + smc_lambda*de/dt
smc_K      = 2.0;    % switching gain (rad/s), kept below max_omega
smc_phi    = 0.5;    % boundary-layer width (rad) -> removes chattering
smc_lambda = 0.12;   % sliding-surface slope

% ---------- ADAPTIVE SPEED CONTROLLER ----------
min_speed = 0.35;
max_accel = 1.20;
max_decel = 2.00;

turn_slow_angle      = pi/3;
obstacle_slow_radius = 10.0;
robot_slow_radius    = 8.0;
boundary_slow_radius = 5.0;

% ---------- PREDICTIVE AVOIDANCE ----------
prediction_horizon = 2.0;
safe_obstacle_dist = 4.0;
safe_robot_dist    = 5.0;

obstacle_repulsion_gain = 5.0;
robot_repulsion_gain    = 5.0;
boundary_repulsion_gain = 3.0;
tangential_gain         = 1.5;

% ---------- DYNAMIC TASK ALLOCATION ----------
task_replan_period = 3.0;
task_switch_margin  = 0.85;
trash_priority_gain = 1.50;

% ---------- BATTERY / ENERGY ----------
battery_initial = 100;
battery_low     = 20;
battery_return  = 12;
energy_distance = 0.035;
energy_turn     = 0.004;
energy_disturb  = 0.02;   % extra energy per unit disturbance speed (fighting wind/current)

% ---------- STUCK RECOVERY ----------
stuck_time_limit = 2.0;
stuck_distance_threshold = 0.12;

% ---------- LOCAL-MINIMUM / ORBIT ESCAPE ----------
% APF navigation can settle into a stable limit cycle (orbiting an
% obstacle) when attraction and repulsion balance out. The robot keeps
% moving, so the plain stuck-detector above never fires. This instead
% tracks NET PROGRESS toward the current target over a rolling window.
orbit_check_period    = 3.0;   % seconds between progress checks
orbit_min_progress    = 1.5;   % must close the gap to target by at least this much
orbit_escape_duration = 6.0;   % seconds to run in wall-following escape mode

% ---------- COVERAGE ----------
coverage_spacing = max(3.0, spacing/1.5);
coverage_x = xmin:coverage_spacing:xmax;
coverage_y = ymin:coverage_spacing:ymax;
coverage_grid = false(length(coverage_y), length(coverage_x));

%% ---------------- ROBOT STATE INITIALISATION ----------------

total_wp = size(all_waypoints,1);

% Graphics sizing (was missing -- caused undefined-variable crash when
% drawing each robot's heading arrow below).
detection_radius = 0.05 * W;
arrow_length     = 0.04 * W;

robots = struct();

for r = 1:num_robots_total

    if strcmp(env_name,'River')
        start_x = home_base(1) + (r-1)*8;
        start_y = (ymin+ymax)/2 + (mod(r,2)*2-1)*2;
    else
        start_x = home_base(1) + (r-1)*max(spacing,6);
        start_y = home_base(2) + mod(r-1,2)*3;
    end

    robots(r).x = start_x;
    robots(r).y = start_y;
    robots(r).theta = 0;

    robots(r).v = min(max(robot_speeds(r),min_speed),10);
    robots(r).desired_v = robots(r).v;

    robots(r).done = false;
    robots(r).returning = false;
    robots(r).finish_time = NaN;

    % Task:
    % 1 = trash collection
    % 2 = coverage waypoint
    % 3 = return home
    robots(r).task_type = 2;
    robots(r).task_index = 1;

    robots(r).target = [start_x start_y];

    % PID memory
    robots(r).heading_integral = 0;
    robots(r).previous_heading_error = 0;
    robots(r).last_omega = 0;

    % Effective (adaptive) PID gains
    robots(r).Kp_eff = Kp_heading;
    robots(r).Ki_eff = Ki_heading;
    robots(r).Kd_eff = Kd_heading;

    % Stuck detection / recovery (recovery_direction is now stored per
    % robot instead of a shared script variable, so simultaneous
    % recoveries on different robots can't overwrite each other's state)
    robots(r).previous_position = [start_x start_y];
    robots(r).stuck_timer = 0;
    robots(r).recovery_timer = 0;
    robots(r).recovery_direction = 1;

    % Local-minimum / orbit escape (see ROBOT UPDATE loop)
    robots(r).last_target          = [start_x start_y];
    robots(r).orbit_checkpoint_time = 0;
    robots(r).orbit_checkpoint_dist = 0;
    robots(r).escape_timer          = 0;
    robots(r).escape_dir            = 1;
    robots(r).orbit_events          = 0;

    % Energy
    robots(r).battery = battery_initial;
    robots(r).energy_used = 0;

    % Metrics
    robots(r).distance = 0;
    robots(r).near_misses = 0;
    robots(r).replans = 0;
    robots(r).safety_overrides = 0;
    robots(r).trash_collected = 0;

    % Disturbance metrics
    robots(r).drift_distance  = 0;   % total displacement pushed by the environment
    robots(r).ground_distance = 0;   % actual distance moved over ground
    robots(r).dist_mag_sum    = 0;
    robots(r).dist_mag_max    = 0;
    robots(r).dist_steps      = 0;
    robots(r).last_dist_mag   = 0;

    % Heading-control diagnostics (logged every step)
    robots(r).field_angle_last = 0;
    robots(r).herr_last        = 0;
    robots(r).dherr_last       = 0;
    robots(r).tdist_last       = 0;

    % Dynamic coverage progress
    robots(r).coverage_target = 1;

    % Graphics
    rcolor = robot_colors(r,:);

    robots(r).body = plot(start_x,start_y,'o', ...
        'MarkerSize',14,'MarkerFaceColor',rcolor,'MarkerEdgeColor','k');

    robots(r).dir = quiver(start_x,start_y, ...
        arrow_length*cos(0),arrow_length*sin(0),0, ...
        'k','LineWidth',2);

    robots(r).label = text(start_x+1,start_y+1.5, ...
        sprintf('R%d',r), ...
        'FontSize',8,'Color',rcolor,'FontWeight','bold');

    % Trajectory trail
    robots(r).trail_x = start_x;
    robots(r).trail_y = start_y;
    robots(r).trail = plot(start_x,start_y,'-', ...
        'Color',rcolor,'LineWidth',1);
end

%% ---------------- DYNAMIC TASK ALLOCATION STATE ----------------
% claimed_by(i):
%   0 = unassigned
%   r = currently assigned to Robot r
claimed_by = zeros(num_trash,1);

% Dynamic coverage waypoint ownership
coverage_claimed = zeros(total_wp,1);

%% ---------------- PERFORMANCE / CONTROL LOGS ----------------

sim_time = 0;

time_log = [];
trash_log = [];
coverage_log = [];
replan_log = [];
safety_log = [];
orbit_log = [];

battery_log = zeros(0,num_robots_total);
speed_log   = zeros(0,num_robots_total);
omega_log   = zeros(0,num_robots_total);

% ---- Per-robot metric logs ----
robot_cov_grid = false(length(coverage_y), length(coverage_x), num_robots_total);

trash_r_log = zeros(0,num_robots_total);   % trash per robot
dist_r_log  = zeros(0,num_robots_total);   % distance per robot
cov_r_log   = zeros(0,num_robots_total);   % coverage % per robot
kp_log      = zeros(0,num_robots_total);   % adaptive Kp per robot
ki_log      = zeros(0,num_robots_total);   % adaptive Ki per robot
kd_log      = zeros(0,num_robots_total);   % adaptive Kd per robot

% ---- position / heading / stability logs ----
pos_x_log   = zeros(0,num_robots_total);
pos_y_log   = zeros(0,num_robots_total);
theta_log   = zeros(0,num_robots_total);   % heading (wrapped to +-pi)
desired_log = zeros(0,num_robots_total);   % desired heading from the APF
herr_log    = zeros(0,num_robots_total);   % heading error
dherr_log   = zeros(0,num_robots_total);   % heading error derivative
tdist_log   = zeros(0,num_robots_total);   % distance to current target
active_log  = false(0,num_robots_total);   % robot still on mission
coll_pos    = zeros(0,4);                  % [x y robot time] of each pick-up
dmag_log    = zeros(0,num_robots_total);   % disturbance speed felt per robot

wind_log = [];   % wind speed
cur_log  = [];   % current speed
wave_log = [];   % wave push (signed)

collection_time = [];
collection_type = [];

total_distance = zeros(1,num_robots_total);
near_miss_count = 0;
replan_count = 0;
safety_override_count = 0;

%% ---------------- UI / LEGEND ----------------

stats_text = text(xlim_range(1)+1,ylim_range(2)-3,'', ...
    'FontSize',9,'BackgroundColor','w','EdgeColor','k');

legend_handles = gobjects(num_robots_total,1);

for r = 1:num_robots_total
    legend_handles(r) = plot(nan,nan,'o', ...
        'MarkerFaceColor',robot_colors(r,:), ...
        'MarkerEdgeColor','k', ...
        'MarkerSize',10, ...
        'DisplayName',sprintf('Robot %d',r));
end

legend(legend_handles,'Location','southeast');

% Wind indicator (top-right): arrow = direction, length = strength
wind_x = xlim_range(2) - 0.07*W;
wind_y = ylim_range(2) - 0.20*H;
wind_arrow_len = 0.06*W;
wind_arrow = quiver(wind_x,wind_y,0,0,0,'Color',[0.1 0.4 0.1], ...
    'LineWidth',2,'MaxHeadSize',2);
wind_text = text(wind_x-0.11*W, wind_y-0.07*H,'', ...
    'FontSize',8,'BackgroundColor','w');

%% ================================================================
%  MAIN DYNAMIC CONTROL LOOP
%  ================================================================

all_done = false;
next_task_replan = 0;

while ~all_done

    %% ------------------------------------------------------------
    %  ENVIRONMENTAL DISTURBANCE UPDATE
    %  Wind = steady base + Ornstein-Uhlenbeck gusts (mean-reverting
    %  random walk). Current and waves are evaluated per position in
    %  disturbance_at().
    % ------------------------------------------------------------

    wind_gust = wind_gust - (wind_gust/gust_tau)*dt + ...
        gust_sigma*sqrt(2*dt/gust_tau)*randn(rs_gust,1,2);

    yaw_noise    = randn(rs_yaw,1,num_robots_total);   % same draws for every controller

    wind_vec     = dist_scale*(wind_base + wind_gust);
    cur_vec      = dist_scale*current_base;
    wave_amp_now = dist_scale*wave_amp;
    wave_now     = wave_amp_now*sin(2*pi*wave_freq*sim_time);

    env_dist = struct('wind',wind_vec,'cur',cur_vec, ...
        'wave_amp',wave_amp_now,'wave_freq',wave_freq, ...
        'windage',windage,'river',strcmp(env_name,'River'), ...
        'ymin',ymin,'ymax',ymax,'t',sim_time);

    %% ------------------------------------------------------------
    %  ENVIRONMENT VISUAL UPDATE (waves / flow / wind / bobbing)
    % ------------------------------------------------------------

    wspd_now  = norm(wind_vec);
    bob_amp   = 0.006*W_v*min(wave_amp_now/0.5,1.5);   % visual heave only
    bob_phase = 2*pi*wave_freq*2*sim_time;

    if vis_on

        % ---- wave ripples: crests travel downwind, direction eases
        % toward the current wind heading so gusts don't snap them ----
        if wspd_now > 0.05
            tgt = atan2(wind_vec(2),wind_vec(1));
            wave_ang = wave_ang + 0.03*atan2(sin(tgt-wave_ang),cos(tgt-wave_ang));
        end
        wave_off = wave_off + wave_len*wave_freq*dt;

        e_hat = [cos(wave_ang) sin(wave_ang)];
        n_hat = [-sin(wave_ang) cos(wave_ang)];

        amp_vis = 0.10*wave_len*min(sqrt(wave_amp_now/0.5),1.2);
        s_j     = wave_len*wave_j + mod(wave_off,wave_len);
        wig     = amp_vis*sin(2*pi*wave_u/(1.7*wave_len) + 0.9*wave_j ...
                              - 2*pi*wave_freq*sim_time);
        along   = s_j + wig;

        WX = wave_cx + along*e_hat(1) + wave_u*n_hat(1);
        WY = wave_cy + along*e_hat(2) + wave_u*n_hat(2);

        in_w = inpolygon(WX,WY,boundary(:,1),boundary(:,2)) & wave_mask;
        WX(~in_w) = NaN;
        WY(~in_w) = NaN;
        WX(end+1,:) = NaN;
        WY(end+1,:) = NaN;
        set(wave_line,'XData',WX(:),'YData',WY(:));

        % ---- water-flow particles (real current + wind + wave field) ----
        fv = disturbance_field(flow_pos(:,1),flow_pos(:,2),env_dist);
        flow_pos = flow_pos + flow_gain*fv*dt;
        flow_age = flow_age + dt;

        in_f = inpolygon(flow_pos(:,1),flow_pos(:,2),boundary(:,1),boundary(:,2));
        dead = ~in_f | (flow_age > flow_life);
        if any(dead)
            n_dead = nnz(dead);
            flow_pos(dead,:) = spawn_in_poly(n_dead,boundary,xlim_range,ylim_range);
            flow_age(dead)   = 0;
            flow_life(dead)  = 8 + 12*rand(n_dead,1);
        end

        tail_v = flow_gain*fv*0.8;
        tail_l = sqrt(sum(tail_v.^2,2));
        tail_v = tail_v .* min(1, flow_tail_max./max(tail_l,1e-9));

        TX = [flow_pos(:,1)'; flow_pos(:,1)'-tail_v(:,1)'; NaN(1,n_flow)];
        TY = [flow_pos(:,2)'; flow_pos(:,2)'-tail_v(:,2)'; NaN(1,n_flow)];
        set(flow_line,'XData',TX(:),'YData',TY(:));
        set(flow_dots,'XData',flow_pos(:,1),'YData',flow_pos(:,2));

        % ---- wind streaks across the whole scene ----
        if wspd_now > 0.02
            wdir_v = wind_vec/wspd_now;
            wind_pos = wind_pos + wind_gain*wind_vec*dt;
            wind_pos(:,1) = xlim_range(1) + mod(wind_pos(:,1)-xlim_range(1), W_v);
            wind_pos(:,2) = ylim_range(1) + mod(wind_pos(:,2)-ylim_range(1), H_v);

            slen = min(0.03*W_v + 0.05*W_v*wspd_now, 0.15*W_v);
            SX = [wind_pos(:,1)'; wind_pos(:,1)'-slen*wdir_v(1); NaN(1,n_wind)];
            SY = [wind_pos(:,2)'; wind_pos(:,2)'-slen*wdir_v(2); NaN(1,n_wind)];
            set(wind_streak,'XData',SX(:),'YData',SY(:));
        else
            set(wind_streak,'XData',NaN,'YData',NaN);
        end

        % ---- water surface gets darker/rougher with wind ----
        rough = min(wspd_now/2,1);
        set(water_patch,'FaceColor',water_color*(1-0.25*rough));
    end

    %% ------------------------------------------------------------
    %  DYNAMIC ENVIRONMENT UPDATE
    %  Moving obstacles and floating trash change the world state.
    % ------------------------------------------------------------

    for k = 1:num_obstacles

        if ~obstacle_float_flags(k)
            continue;
        end

        obs = obstacles(k,:);

        predicted_x = obs(1) + obs_velocity(k,1)*dt;
        predicted_y = obs(2) + obs_velocity(k,2)*dt;

        if obs(3)==1
            obs_r = obs(4);
        elseif obs(3)==2
            obs_r = max(obs(4),obs(5));
        else
            obs_r = obs(4);
        end

        clearance = obs_r + 1.5;

        test_angles = linspace(0,2*pi,12);
        px = predicted_x + clearance*cos(test_angles);
        py = predicted_y + clearance*sin(test_angles);

        if all(inpolygon(px,py,boundary(:,1),boundary(:,2)))

            obstacle_collision = false;

            for j = 1:num_obstacles

                if j==k
                    continue;
                end

                obs_j = obstacles(j,:);

                if obs_j(3)==1
                    rj = obs_j(4);
                elseif obs_j(3)==2
                    rj = max(obs_j(4),obs_j(5));
                else
                    rj = obs_j(4);
                end

                if norm([predicted_x predicted_y]-obs_j(1:2)) ...
                        < obs_r+rj+1.5

                    obstacle_collision = true;
                    break;
                end
            end

            if ~obstacle_collision
                obstacles(k,1) = predicted_x;
                obstacles(k,2) = predicted_y;
            else
                obs_velocity(k,:) = -obs_velocity(k,:);
            end

        else
            % Reflect the obstacle velocity when it approaches
            % the boundary.
            obs_velocity(k,:) = -obs_velocity(k,:);
        end

        % Redraw floating obstacle.
        cx = obstacles(k,1);
        cy = obstacles(k,2);

        switch obs(3)

            case 1
                th = linspace(0,2*pi,50);
                set(obs_handles{k}, ...
                    'XData',cx+obs(4)*cos(th), ...
                    'YData',cy+obs(4)*sin(th));

            case 2
                sx = obs(4);
                sy = max(obs(5),obs(4)*0.6);

                set(obs_handles{k}, ...
                    'XData',[cx-sx cx+sx cx+sx cx-sx], ...
                    'YData',[cy-sy cy-sy cy+sy cy+sy]);

            case 3
                set(obs_handles{k}, ...
                    'XData',[cx cx+obs(4) cx-obs(4)], ...
                    'YData',[cy+obs(4) cy-obs(4)/2 cy-obs(4)/2]);
        end
    end

    %% ------------------------------------------------------------
    %  DYNAMIC TRASH MOTION
    % ------------------------------------------------------------

    for i = 1:num_trash

        if collected(i)==1
            continue;
        end

        % Wind / current / waves also push floating trash around.
        trash_drift = trash_coupling * ...
            disturbance_at(trash(i,1),trash(i,2),env_dist);
        candidate_pos = trash(i,:) + (trash_velocity(i,:) + trash_drift)*dt;

        inside_candidate = inpolygon(candidate_pos(1),candidate_pos(2), ...
                boundary(:,1),boundary(:,2));

        % Don't just wait until trash is about to leave the water --
        % keep it away from the shoreline by the same margin used when
        % spawning it, so it never ends up hugging the edge where the
        % robot struggles to close the last bit of distance.
        too_close_to_shore = false;
        if inside_candidate
            % The River's right edge is a flow exit (trash wraps back
            % to the inlet there), not a shoreline to avoid -- only
            % the top/bottom banks (and other environments' actual
            % shorelines) should trigger the steer-back below.
            near_river_exit = strcmp(env_name,'River') && ...
                candidate_pos(1) > (xmax - boundary_margin);

            if ~near_river_exit
                [shore_dist, shore_pt] = distance_to_polygon_boundary( ...
                    candidate_pos(1), candidate_pos(2), boundary);
                if shore_dist < boundary_margin
                    too_close_to_shore = true;
                end
            end
        end

        if inside_candidate && ~too_close_to_shore

            valid = true;

            for k = 1:num_obstacles

                obs = obstacles(k,:);

                if obs(3)==1
                    clearance = obs(4)+2.5;
                elseif obs(3)==2
                    clearance = max(obs(4),obs(5))+2.5;
                else
                    clearance = obs(4)+2.5;
                end

                if norm(candidate_pos-obs(1:2)) < clearance
                    valid = false;
                    break;
                end
            end

            if valid
                trash(i,:) = candidate_pos;
            else
                trash_velocity(i,:) = -trash_velocity(i,:);
            end

        elseif too_close_to_shore

            % Steer back toward open water instead of letting it
            % linger against the shore. Re-point the velocity inward
            % (blended with a little of its old heading so motion
            % still looks natural) and take a step this frame if that
            % step is itself safe.
            push_vec = trash(i,:) - shore_pt;
            push_norm = norm(push_vec);
            if push_norm > 0.001
                push_dir = push_vec / push_norm;
            else
                push_dir = [0 0];
            end

            speed_mag = norm(trash_velocity(i,:));
            trash_velocity(i,:) = 0.7*speed_mag*push_dir + 0.3*trash_velocity(i,:);

            retry_pos = trash(i,:) + trash_velocity(i,:)*dt;
            if inpolygon(retry_pos(1),retry_pos(2),boundary(:,1),boundary(:,2))
                trash(i,:) = retry_pos;
            end

        elseif strcmp(env_name,'River') && candidate_pos(1)>xmax

            trash(i,1) = xmin+2;
            trash(i,2) = ymin+(ymax-ymin)*rand();

        else

            trash_velocity(i,2) = -trash_velocity(i,2);

            if candidate_pos(1)<xmin
                trash_velocity(i,1) = abs(trash_velocity(i,1));
            end
        end

        set(trash_plot(i), ...
            'XData',trash(i,1), ...
            'YData',trash(i,2) + bob_amp*sin(bob_phase + 0.15*(trash(i,1)+trash(i,2))));
    end

    %% ============================================================
    %  DYNAMIC TASK ALLOCATION
    %  Robots dynamically select tasks based on distance, speed,
    %  battery and trash priority.
    % ============================================================

    if sim_time >= next_task_replan

        replan_count = replan_count + 1;

        % Release previous trash assignments.
        for r = 1:num_robots_total
            if robots(r).task_type==1
                old_idx = robots(r).task_index;

                if old_idx>=1 && old_idx<=num_trash ...
                        && collected(old_idx)==0 ...
                        && claimed_by(old_idx)==r

                    claimed_by(old_idx)=0;
                end
            end
        end

        % Release coverage assignments.
        coverage_claimed(:)=0;

        % First allocate trash to robots.
        available_trash = find(collected==0);

        for r = 1:num_robots_total

            if robots(r).done || robots(r).returning
                continue;
            end

            if robots(r).battery <= battery_return
                continue;
            end

            if isempty(available_trash)
                break;
            end

            best_cost = inf;
            best_trash = 0;

            for q = 1:length(available_trash)

                i = available_trash(q);

                if claimed_by(i)~=0
                    continue;
                end

                d = norm(robots(r).target-trash(i,:));

                % High-priority trash is slightly preferred.
                priority = 1 + trash_priority_gain * ...
                    (1/(1+d));

                estimated_time = d/max(robots(r).v,min_speed);

                battery_penalty = 1 + ...
                    max(0,(30-robots(r).battery)/30);

                cost = estimated_time*priority*battery_penalty;

                if cost < best_cost
                    best_cost = cost;
                    best_trash = i;
                end
            end

            if best_trash>0
                claimed_by(best_trash)=r;
                robots(r).task_type=1;
                robots(r).task_index=best_trash;
                robots(r).replans=robots(r).replans+1;
            end
        end

        % Allocate coverage work to robots that did not receive trash.
        for r = 1:num_robots_total

            if robots(r).done || robots(r).returning
                continue;
            end

            if robots(r).task_type==1
                continue;
            end

            best_wp = 0;
            best_cost = inf;

            for w = 1:total_wp

                if coverage_claimed(w)~=0
                    continue;
                end

                wp = all_waypoints(w,:);
                d = norm([robots(r).x robots(r).y]-wp);

                cost = d/max(robots(r).v,min_speed);

                if cost<best_cost
                    best_cost=cost;
                    best_wp=w;
                end
            end

            if best_wp>0
                coverage_claimed(best_wp)=r;
                robots(r).task_type=2;
                robots(r).task_index=best_wp;
                robots(r).coverage_target=best_wp;
            end
        end

        next_task_replan = sim_time + task_replan_period;
    end

    %% ============================================================
    %  ROBOT UPDATE
    % ============================================================

    for r = 1:num_robots_total

        if robots(r).done
            continue;
        end

        rx = robots(r).x;
        ry = robots(r).y;

        %% --------------------------------------------------------
        %  BATTERY / ENERGY MANAGEMENT
        % --------------------------------------------------------

        if robots(r).battery <= battery_return
            old_task_type = robots(r).task_type;
            old_task = robots(r).task_index;

            if old_task_type==1 && old_task>=1 && old_task<=num_trash ...
                    && collected(old_task)==0 ...
                    && claimed_by(old_task)==r
                claimed_by(old_task)=0;
            end

            robots(r).returning = true;
            robots(r).task_type = 3;
        end

        %% --------------------------------------------------------
        %  DYNAMIC TASK TARGET
        % --------------------------------------------------------

        if robots(r).returning || robots(r).task_type==3

            robots(r).task_type=3;
            target = home_base;

        elseif robots(r).task_type==1

            trash_id = robots(r).task_index;

            if trash_id<1 || trash_id>num_trash || collected(trash_id)==1

                robots(r).task_type=0;
                target = [rx ry];

            else

                % Important: use the CURRENT trash position.
                % This makes the robot dynamically follow moving trash.
                target = trash(trash_id,:);

                if norm([rx ry]-target)<=2.0

                    collected(trash_id)=1;
                    trash(trash_id,:)=[NaN NaN];

                    set(trash_plot(trash_id),'Visible','off');

                    collection_time(end+1)=sim_time;
                    collection_type(end+1)=trash_color_idx(trash_id);
                    coll_pos(end+1,:) = [rx ry r sim_time]; %#ok<SAGROW>

                    robots(r).trash_collected=robots(r).trash_collected+1;

                    claimed_by(trash_id)=0;

                    robots(r).task_type=0;

                    continue;
                end
            end

        elseif robots(r).task_type==2

            wp_id = robots(r).task_index;

            if wp_id<1 || wp_id>total_wp
                robots(r).task_type=0;
                target=[rx ry];
            else

                target=all_waypoints(wp_id,:);

                if norm([rx ry]-target)<1.5

                    coverage_claimed(wp_id)=0;

                    robots(r).task_type=0;

                    continue;
                end
            end

        else

            % Emergency fallback: nearest uncollected trash.
            remaining=find(collected==0);

            if ~isempty(remaining)

                best_d=inf;
                best_i=remaining(1);

                for q=1:length(remaining)
                    d=norm([rx ry]-trash(remaining(q),:));

                    if d<best_d
                        best_d=d;
                        best_i=remaining(q);
                    end
                end

                claimed_by(best_i)=r;
                robots(r).task_type=1;
                robots(r).task_index=best_i;

                target=trash(best_i,:);

            else

                robots(r).returning=true;
                robots(r).task_type=3;
                target=home_base;
            end
        end

        robots(r).target=target;

        if norm(target - robots(r).last_target) > 0.5
            robots(r).last_target = target;
            robots(r).orbit_checkpoint_time = sim_time;
            robots(r).orbit_checkpoint_dist = norm(target-[rx ry]);
        end

        %% ========================================================
        %  PREDICTIVE OBSTACLE AVOIDANCE
        %  Predict obstacle position several seconds ahead instead
        %  of waiting until the robot is already close.
        % ========================================================

        obstacle_fx=0;
        obstacle_fy=0;

        nearest_obstacle_distance=inf;

        for k=1:num_obstacles

            obs=obstacles(k,:);

            if obs(3)==1
                obs_radius=obs(4);
            elseif obs(3)==2
                obs_radius=max(obs(4),obs(5));
            else
                obs_radius=obs(4);
            end

            if obstacle_float_flags(k)

                predicted_obs=obs(1:2) + ...
                    obs_velocity(k,:)*prediction_horizon;

            else

                predicted_obs=obs(1:2);
            end

            diff_vec=[rx ry]-predicted_obs;
            d=norm(diff_vec);

            nearest_obstacle_distance= ...
                min(nearest_obstacle_distance,max(0,d-obs_radius));

            influence_radius=obs_radius+obstacle_slow_radius;

            if d<influence_radius && d>0.001

                strength=obstacle_repulsion_gain * ...
                    (1/d-1/influence_radius)/(d^2);

                obstacle_fx=obstacle_fx + strength*diff_vec(1)/d;
                obstacle_fy=obstacle_fy + strength*diff_vec(2)/d;

                % Tangential component helps the robot go around the
                % obstacle rather than stopping directly in front of it.
                obstacle_fx=obstacle_fx + ...
                    tangential_gain*(-diff_vec(2)/d)*(1-d/influence_radius);

                obstacle_fy=obstacle_fy + ...
                    tangential_gain*( diff_vec(1)/d)*(1-d/influence_radius);
            end
        end

        %% ========================================================
        %  PREDICTIVE INTER-ROBOT COLLISION AVOIDANCE
        %  Estimate closest approach between robot trajectories.
        % ========================================================

        robot_fx=0;
        robot_fy=0;

        nearest_robot_distance=inf;

        current_velocity = robots(r).v * ...
            [cos(robots(r).theta),sin(robots(r).theta)];

        for rr=1:num_robots_total

            if rr==r || robots(rr).done
                continue;
            end

            other_velocity = robots(rr).v * ...
                [cos(robots(rr).theta),sin(robots(rr).theta)];

            relative_position = ...
                [robots(rr).x robots(rr).y]-[rx ry];

            relative_velocity = other_velocity-current_velocity;

            rv2=dot(relative_velocity,relative_velocity);

            if rv2>1e-8
                t_ca=-dot(relative_position,relative_velocity)/rv2;
                t_ca=max(0,min(prediction_horizon,t_ca));
            else
                t_ca=0;
            end

            predicted_self=[rx ry]+current_velocity*t_ca;
            predicted_other=[robots(rr).x robots(rr).y]+ ...
                other_velocity*t_ca;

            separation=norm(predicted_self-predicted_other);

            nearest_robot_distance=min(nearest_robot_distance,separation);

            if separation<safe_robot_dist

                near_miss_count=near_miss_count+1;
                robots(r).near_misses=robots(r).near_misses+1;

                away_vec=predicted_self-predicted_other;
                d=norm(away_vec);

                if d>0.001
                    strength=robot_repulsion_gain * ...
                        (safe_robot_dist-separation)/safe_robot_dist;

                    robot_fx=robot_fx+strength*away_vec(1)/d;
                    robot_fy=robot_fy+strength*away_vec(2)/d;
                end
            end
        end

        %% ========================================================
        %  ARTIFICIAL POTENTIAL FIELD NAVIGATION
        %  Attractive force -> target
        %  Repulsive force -> obstacles + robots
        %  Boundary force  -> keep robot inside water
        % ========================================================

        target_vec=target-[rx ry];
        target_distance=norm(target_vec);

        if target_distance>0.001
            target_fx=target_vec(1)/target_distance;
            target_fy=target_vec(2)/target_distance;
        else
            target_fx=0;
            target_fy=0;
        end

        % Boundary repulsion based on the ACTUAL water-body polygon,
        % not just the outer bounding rectangle. For irregular shapes
        % (Lake/Pond/River) the real shoreline can sit well inside the
        % rectangle, so a rectangle-only repulsion let robots get right
        % up against a polygon edge with no slow-down/push-back -- that
        % was the main reason trash sitting near the true shoreline was
        % hard to reach cleanly (the robot would approach too fast, or
        % from an angle that clipped the edge, and then get hard-blocked
        % by the FINAL SAFETY CHECK below).
        [edge_dist, edge_pt] = distance_to_polygon_boundary(rx, ry, boundary);
        inside_poly = inpolygon(rx, ry, boundary(:,1), boundary(:,2));

        boundary_fx=0;
        boundary_fy=0;

        if edge_dist < boundary_slow_radius
            away_vec = [rx ry] - edge_pt;
            dnorm = norm(away_vec);

            if dnorm > 0.001
                strength = boundary_repulsion_gain * ...
                    (boundary_slow_radius - edge_dist) / boundary_slow_radius;

                if inside_poly
                    % Push further into the interior, away from shore.
                    boundary_fx = strength*away_vec(1)/dnorm;
                    boundary_fy = strength*away_vec(2)/dnorm;
                else
                    % Should not normally happen (motion is blocked by
                    % the final safety check), but push firmly back in
                    % just in case.
                    boundary_fx = -3*strength*away_vec(1)/dnorm;
                    boundary_fy = -3*strength*away_vec(2)/dnorm;
                end
            end
        end

        % Outer-rectangle distances are still kept for the adaptive
        % speed controller below (cheap extra safety net; harmless and
        % redundant for the rectangular Pool/Ocean environments).
        left_d=rx-xlim_range(1);
        right_d=xlim_range(2)-rx;
        bottom_d=ry-ylim_range(1);
        top_d=ylim_range(2)-ry;

        %% ========================================================
        %  ENVIRONMENTAL DISTURBANCE AT THIS ROBOT'S POSITION
        % ========================================================

        dist_vec  = disturbance_at(rx,ry,env_dist);
        dist_mag  = norm(dist_vec);
        dist_norm = min(dist_mag/1.5, 1);

        %% ========================================================
        %  LOCAL-MINIMUM / ORBIT DETECTION
        %  APF navigation can settle into a stable limit cycle around
        %  an obstacle when attraction and repulsion balance out. The
        %  robot keeps moving every step, so the plain stuck-detector
        %  (which only checks raw movement) never catches this. Instead
        %  track NET PROGRESS toward the current target over a rolling
        %  window; if the robot is moving but not actually closing the
        %  distance to its goal, it's orbiting.
        % ========================================================

        if sim_time - robots(r).orbit_checkpoint_time >= orbit_check_period

            progress_made = robots(r).orbit_checkpoint_dist - target_distance;

            if progress_made < orbit_min_progress && robots(r).escape_timer <= 0

                robots(r).escape_timer = orbit_escape_duration;

                % Commit to ONE consistent rotation direction (bug-
                % algorithm style wall-following) around whichever
                % obstacle is currently nearest. Picking the tangent
                % that already points roughly toward the target means
                % the robot hugs the correct side of the obstacle
                % instead of the naive "just point at the target"
                % approach, which just drives straight back into the
                % obstacle when the target sits behind it and gets
                % walked into a spiral by the hard collision check.
                nd = inf; npos = [rx ry];
                for k = 1:num_obstacles
                    obs_k = obstacles(k,:);
                    if obs_k(3)==1, ork=obs_k(4);
                    elseif obs_k(3)==2, ork=max(obs_k(4),obs_k(5));
                    else, ork=obs_k(4); end
                    dk = norm([rx ry]-obs_k(1:2)) - ork;
                    if dk < nd
                        nd = dk; npos = obs_k(1:2);
                    end
                end

                % The shoreline itself (not just an obstacle) can be
                % what the robot is orbiting -- this is exactly what
                % happens near a sharp/convex corner of an irregular
                % boundary (Lake/Pond/River), where target attraction
                % and boundary repulsion fight each other and the
                % robot spins in place instead of sliding around the
                % corner. Whichever surface (obstacle or shoreline) is
                % the tighter constraint is what gets wall-followed.
                if edge_dist < nd
                    npos = edge_pt;
                end

                dvec = [rx ry]-npos;
                if norm(dvec) > 0.001
                    tang = [-dvec(2) dvec(1)]/norm(dvec);
                    if dot(tang, target-[rx ry]) >= 0
                        robots(r).escape_dir = 1;
                    else
                        robots(r).escape_dir = -1;
                    end
                else
                    robots(r).escape_dir = 1;
                end

                robots(r).orbit_events = robots(r).orbit_events + 1;
            end

            robots(r).orbit_checkpoint_time = sim_time;
            robots(r).orbit_checkpoint_dist = target_distance;
        end

        if robots(r).escape_timer > 0

            % Wall-following escape: find the currently-nearest obstacle
            % and, if it's actually close enough to matter, follow its
            % boundary tangentially (in the committed direction) with a
            % mild outward push (stay clear of the surface) and a small
            % pull toward the target (so it drifts productively around
            % rather than orbiting forever). If nothing is nearby, just
            % steer straight at the target -- the obstacle has been
            % cleared. Boundary containment stays active throughout,
            % and the FINAL SAFETY CHECK below still hard-blocks any
            % actual collision as a last resort.
            near_k = 0; near_d = inf; near_pos = [rx ry]; near_r = 0;
            for k = 1:num_obstacles
                obs_k = obstacles(k,:);
                if obs_k(3)==1, orad=obs_k(4);
                elseif obs_k(3)==2, orad=max(obs_k(4),obs_k(5));
                else, orad=obs_k(4); end
                dk = norm([rx ry]-obs_k(1:2)) - orad;
                if dk < near_d
                    near_d = dk; near_k = k; near_pos = obs_k(1:2); near_r = orad;
                end
            end

            % Wall-follow whichever surface is the tighter constraint:
            % the nearest obstacle, or the shoreline itself. Near a
            % sharp/convex corner of an irregular boundary the shoreline
            % is usually what's actually causing the orbit, so it needs
            % the same tangential wall-following treatment obstacles
            % already get -- previously only obstacles were handled,
            % which is why boundary-corner traps never resolved.
            use_boundary = (edge_dist < boundary_slow_radius) && ...
                (near_k == 0 || edge_dist <= near_d);

            if use_boundary
                diff_vec = [rx ry]-edge_pt;
                dnow = max(norm(diff_vec), 0.001);
                tangent = robots(r).escape_dir * [-diff_vec(2) diff_vec(1)]/dnow;
                outward = diff_vec/dnow;

                esc_fx = 1.0*tangent(1) + 0.4*outward(1) + 0.3*target_fx;
                esc_fy = 1.0*tangent(2) + 0.4*outward(2) + 0.3*target_fy;
            elseif near_k > 0 && near_d < obstacle_slow_radius
                diff_vec = [rx ry]-near_pos;
                dnow = max(norm(diff_vec), 0.001);
                tangent = robots(r).escape_dir * [-diff_vec(2) diff_vec(1)]/dnow;
                outward = diff_vec/dnow;

                esc_fx = 1.0*tangent(1) + 0.4*outward(1) + 0.3*target_fx;
                esc_fy = 1.0*tangent(2) + 0.4*outward(2) + 0.3*target_fy;
            else
                esc_fx = target_fx;
                esc_fy = target_fy;
            end

            % esc_fx/fy already carries its own outward push away from
            % whichever surface is binding, so adding the FULL boundary
            % repulsion on top (as before) double-counted that force and
            % is what produced the tight spinning loops: the two forces
            % fought each other every step instead of cooperating. Keep
            % only a light touch of it here as a pure safety margin.
            field_fx = esc_fx + 0.3*boundary_fx;
            field_fy = esc_fy + 0.3*boundary_fy;

            if norm([field_fx field_fy])<0.001
                field_angle = robots(r).theta;
            else
                field_angle = atan2(field_fy,field_fx);
            end

            robots(r).escape_timer = robots(r).escape_timer - dt;

        else

            field_fx=target_fx+obstacle_fx+robot_fx+boundary_fx;
            field_fy=target_fy+obstacle_fy+robot_fy+boundary_fy;

            if norm([field_fx field_fy])<0.001
                field_angle=robots(r).theta;
            else
                field_angle=atan2(field_fy,field_fx);
            end
        end

        %% ========================================================
        %  HEADING CONTROLLER (selected by ctrl_id)
        %    1 Adaptive PID  : gains scheduled from error, speed, obstacle
        %                      proximity, disturbance (+ stability guard)
        %    2 Fixed-gain PID: constant Kp/Ki/Kd
        %    3 PD            : constant Kp/Kd, no integral action
        %    4 Sliding-mode  : omega = K*tanh((e + lambda*de/dt)/phi)
        % ========================================================

        heading_error=atan2( ...
            sin(field_angle-robots(r).theta), ...
            cos(field_angle-robots(r).theta));

        heading_derivative = ...
            (heading_error-robots(r).previous_heading_error)/dt;

        switch ctrl_id

            case 1   % ---------- ADAPTIVE PID ----------
                err_norm   = min(abs(heading_error)/pi, 1);
                speed_norm = min(robots(r).v/10, 1);

                if isfinite(nearest_obstacle_distance)
                    near_norm = 1 - min(nearest_obstacle_distance/obstacle_slow_radius, 1);
                else
                    near_norm = 0;
                end

                % Kp: stronger correction for big errors / close obstacles
                Kp_eff = Kp_heading * (1 + adapt_err_gain*err_norm) * ...
                                      (1 + adapt_obs_boost*near_norm);
                Kp_eff = max(Kp_min, min(Kp_max, Kp_eff));

                % Ki: fade out on large errors (anti-windup), boosted by
                % disturbances, off when saturated
                Ki_eff = Ki_heading * (1 - err_norm) * (1 + adapt_dist_boost*dist_norm);
                if abs(robots(r).last_omega) >= 0.98*max_omega
                    Ki_eff = 0;
                end

                % Kd: more damping at high speed / near obstacles ...
                Kd_eff = Kd_heading * (1 + adapt_speed_damp*speed_norm) * ...
                                      (1 + 0.5*near_norm);
                Kd_eff = max(Kd_min, min(Kd_max, Kd_eff));

                % ... but never beyond the stability limit of the sampled
                % loop (necessary condition  Kd < 1 - dt*Kp/2 - Ki*dt^2/4).
                % Without this guard a large Kd with a large Kp makes the
                % discrete loop unstable (poles outside the unit circle).
                Kd_cap = stab_margin*(1 - dt*Kp_eff/2 - Ki_eff*dt^2/4);
                Kd_eff = min(Kd_eff, max(Kd_cap, 0.05));

            case 2   % ---------- FIXED-GAIN PID ----------
                Kp_eff = Kp_heading;
                Ki_eff = Ki_heading;
                Kd_eff = Kd_heading;

            case 3   % ---------- PD ----------
                Kp_eff = Kp_heading;
                Ki_eff = 0;
                Kd_eff = Kd_heading;

            otherwise % ---------- SLIDING MODE ----------
                % Equivalent linear gains inside the boundary layer
                % (used only for logging / stability analysis).
                Kp_eff = smc_K/smc_phi;
                Ki_eff = 0;
                Kd_eff = smc_lambda*smc_K/smc_phi;
        end

        robots(r).Kp_eff = Kp_eff;
        robots(r).Ki_eff = Ki_eff;
        robots(r).Kd_eff = Kd_eff;

        if ctrl_id == 4

            s_slide = heading_error + smc_lambda*heading_derivative;
            omega   = smc_K*tanh(s_slide/smc_phi);
            robots(r).heading_integral = 0;

        else

            if ctrl_id == 3
                robots(r).heading_integral = 0;
            else
                robots(r).heading_integral = ...
                    robots(r).heading_integral + heading_error*dt;

                robots(r).heading_integral = ...
                    max(-integral_limit,min(integral_limit, ...
                    robots(r).heading_integral));
            end

            omega = Kp_eff*heading_error + ...
                    Ki_eff*robots(r).heading_integral + ...
                    Kd_eff*heading_derivative;
        end

        omega=max(-max_omega,min(max_omega,omega));

        robots(r).previous_heading_error=heading_error;
        robots(r).last_omega=omega;

        % diagnostics for the position / heading / stability logs
        robots(r).field_angle_last = field_angle;
        robots(r).herr_last        = heading_error;
        robots(r).dherr_last       = heading_derivative;
        robots(r).tdist_last       = target_distance;

        %% ========================================================
        %  ADAPTIVE SPEED CONTROL
        %  Speed decreases for:
        %    - sharp turns
        %    - nearby obstacles
        %    - nearby robots
        %    - boundary proximity
        %    - low battery
        %    - final approach to target
        % ========================================================

        base_speed=min(robot_speeds(r),10);

        turn_factor=1-min(abs(heading_error)/turn_slow_angle,1)*0.65;

        if isfinite(nearest_obstacle_distance)
            obstacle_factor=0.45+0.55*min( ...
                nearest_obstacle_distance/obstacle_slow_radius,1);
        else
            obstacle_factor=1;
        end

        if isfinite(nearest_robot_distance)
            robot_factor=0.50+0.50*min( ...
                nearest_robot_distance/robot_slow_radius,1);
        else
            robot_factor=1;
        end

        % Boundary proximity now also accounts for the real shoreline
        % distance (edge_dist), not just the outer rectangle, so the
        % robot actually slows down while lining up on shoreline trash
        % instead of speeding straight at the edge and getting blocked.
        boundary_distance=min([left_d,right_d,bottom_d,top_d,edge_dist]);

        boundary_factor=0.50+0.50*min( ...
            boundary_distance/boundary_slow_radius,1);

        battery_factor=0.55+0.45*min(robots(r).battery/100,1);

        if target_distance<8
            target_factor=0.35+0.65*min(target_distance/8,1);
        else
            target_factor=1;
        end

        desired_speed=base_speed * ...
            min([turn_factor,obstacle_factor, ...
                 robot_factor,boundary_factor, ...
                 battery_factor,target_factor]);

        desired_speed=max(min_speed,min(base_speed,desired_speed));

        % Apply acceleration/deceleration limits.
        speed_change=desired_speed-robots(r).v;

        if speed_change>max_accel*dt
            speed_change=max_accel*dt;
        elseif speed_change<-max_decel*dt
            speed_change=-max_decel*dt;
        end

        robots(r).desired_v=desired_speed;
        robots(r).v=max(min_speed,robots(r).v+speed_change);

        %% ========================================================
        %  STUCK DETECTION AND RECOVERY
        % ========================================================

        movement_since_last=norm( ...
            [rx ry]-robots(r).previous_position);

        if movement_since_last<stuck_distance_threshold
            robots(r).stuck_timer=robots(r).stuck_timer+dt;
        else
            robots(r).stuck_timer=0;
        end

        robots(r).previous_position=[rx ry];

        if robots(r).stuck_timer>stuck_time_limit

            % Recovery manoeuvre:
            % temporarily rotate toward the free side.
            % (Stored per-robot -- see note in ROBOT MOTION/DYNAMICS.)
            robots(r).recovery_direction=(-1)^r;

            robots(r).theta=robots(r).theta + ...
                robots(r).recovery_direction*pi/2;

            robots(r).heading_integral=0;
            robots(r).previous_heading_error=0;

            robots(r).stuck_timer=0;
            robots(r).recovery_timer=1.0;

            robots(r).replans=robots(r).replans+1;
            replan_count=replan_count+1;
        end

        %% ========================================================
        %  ROBOT MOTION / DYNAMICS
        % ========================================================

        if robots(r).recovery_timer>0

            % Use the robot's OWN stored recovery direction, not a
            % script-level variable shared across all robots in this
            % loop -- otherwise one robot's recovery could hijack the
            % heading of another robot recovering in the same tick.
            robots(r).theta=robots(r).theta+0.25*robots(r).recovery_direction;
            robots(r).recovery_timer= ...
                robots(r).recovery_timer-dt;
        else

            robots(r).theta=robots(r).theta+omega*dt;
        end

        % Wave-induced yaw jitter, then commanded motion + environmental
        % drift. The FINAL SAFETY CHECK below validates the drifted position.
        robots(r).theta = robots(r).theta + ...
            dist_scale*yaw_sigma*sqrt(dt)*yaw_noise(r);

        next_x=rx+(robots(r).v*cos(robots(r).theta)+dist_vec(1))*dt;
        next_y=ry+(robots(r).v*sin(robots(r).theta)+dist_vec(2))*dt;

        %% --------------------------------------------------------
        %  FINAL SAFETY CHECK
        % --------------------------------------------------------

        safe_position = is_position_safe(next_x, next_y, boundary, obstacles);

        if ~safe_position
            % Don't just freeze in place: that was the main reason
            % trash sitting close to the shoreline (or an obstacle)
            % could never actually be reached -- the robot would stop
            % just short of the collection radius and stay stuck there
            % every subsequent step, since the intended full step kept
            % getting rejected. Instead, try progressively smaller
            % steps along the same heading so the robot can still creep
            % forward right up to the safe limit.
            step_fracs = [0.5 0.25 0.1 0.05];

            for sf = step_fracs
                cand_x = rx + (next_x - rx) * sf;
                cand_y = ry + (next_y - ry) * sf;

                if is_position_safe(cand_x, cand_y, boundary, obstacles)
                    next_x = cand_x;
                    next_y = cand_y;
                    safe_position = true;
                    break;
                end
            end
        end

        if safe_position
            robots(r).x=next_x;
            robots(r).y=next_y;
            robots(r).ground_distance = robots(r).ground_distance + ...
                norm([next_x-rx next_y-ry]);
        else
            % Stop and rotate away from danger. This is a per-timestep
            % collision-safety override, not a "replan" in the task
            % sense -- tracked separately so the dashboard doesn't
            % conflate the two very different event rates.
            robots(r).v=max(min_speed,robots(r).v*0.5);

            robots(r).theta=robots(r).theta+pi/2;

            robots(r).safety_overrides=robots(r).safety_overrides+1;
            safety_override_count=safety_override_count+1;
        end

        %% --------------------------------------------------------
        %  DISTANCE + ENERGY UPDATE
        % --------------------------------------------------------

        travelled=robots(r).v*dt;

        robots(r).distance=robots(r).distance+travelled;

        turn_energy=energy_turn*(omega^2)*dt;

        disturbance_energy=energy_disturb*dist_mag*dt;

        consumed=energy_distance*travelled+turn_energy+disturbance_energy;

        robots(r).battery=max(0,robots(r).battery-consumed);

        robots(r).energy_used=robots(r).energy_used+consumed;

        total_distance(r)=robots(r).distance;

        robots(r).drift_distance = robots(r).drift_distance + dist_mag*dt;
        robots(r).dist_mag_sum   = robots(r).dist_mag_sum + dist_mag;
        robots(r).dist_mag_max   = max(robots(r).dist_mag_max, dist_mag);
        robots(r).dist_steps     = robots(r).dist_steps + 1;
        robots(r).last_dist_mag  = dist_mag;

        %% --------------------------------------------------------
        %  COVERAGE GRID UPDATE (global + per-robot)
        % --------------------------------------------------------

        [~,gx]=min(abs(coverage_x-robots(r).x));
        [~,gy]=min(abs(coverage_y-robots(r).y));

        radius_cells=1;

        x1=max(1,gx-radius_cells);
        x2=min(length(coverage_x),gx+radius_cells);

        y1=max(1,gy-radius_cells);
        y2=min(length(coverage_y),gy+radius_cells);

        coverage_grid(y1:y2,x1:x2)=true;
        robot_cov_grid(y1:y2,x1:x2,r)=true;

        %% --------------------------------------------------------
        %  TRAJECTORY
        % --------------------------------------------------------

        robots(r).trail_x(end+1)=robots(r).x;
        robots(r).trail_y(end+1)=robots(r).y;

        set(robots(r).trail, ...
            'XData',robots(r).trail_x, ...
            'YData',robots(r).trail_y);

    end

    %% ============================================================
    %  RETURN-TO-HOME LOGIC
    % ============================================================

    if sum(collected)==num_trash

        for r=1:num_robots_total
            if ~robots(r).done
                robots(r).returning=true;
                robots(r).task_type=3;
            end
        end
    end

    for r=1:num_robots_total

        if robots(r).returning && ~robots(r).done

            if norm([robots(r).x robots(r).y]-home_base)<2

                robots(r).done=true;
                robots(r).v=0;
                robots(r).finish_time=sim_time;
            end
        end
    end

    %% ============================================================
    %  COVERAGE / LOGGING
    % ============================================================

    sim_time=sim_time+dt;

    coverage_percent=100*sum(coverage_grid(:))/ ...
        numel(coverage_grid);

    time_log(end+1)=sim_time;
    trash_log(end+1)=sum(collected);
    coverage_log(end+1)=coverage_percent;
    replan_log(end+1)=replan_count;
    safety_log(end+1)=safety_override_count;
    orbit_log(end+1)=sum([robots.orbit_events]);

    current_battery=zeros(1,num_robots_total);
    current_speed=zeros(1,num_robots_total);
    current_omega=zeros(1,num_robots_total);

    for r=1:num_robots_total
        current_battery(r)=robots(r).battery;
        current_speed(r)=robots(r).v;
        current_omega(r)=robots(r).last_omega;
    end

    battery_log(end+1,:)=current_battery;
    speed_log(end+1,:)=current_speed;
    omega_log(end+1,:)=current_omega;

    % ---- Per-robot metric logging ----
    trash_r = zeros(1,num_robots_total);
    dist_r  = zeros(1,num_robots_total);
    cov_r   = zeros(1,num_robots_total);
    kp_r    = zeros(1,num_robots_total);
    ki_r    = zeros(1,num_robots_total);
    kd_r    = zeros(1,num_robots_total);

    for r = 1:num_robots_total
        trash_r(r) = robots(r).trash_collected;
        dist_r(r)  = robots(r).distance;
        cov_r(r)   = 100*nnz(robot_cov_grid(:,:,r))/numel(coverage_grid);
        kp_r(r)    = robots(r).Kp_eff;
        ki_r(r)    = robots(r).Ki_eff;
        kd_r(r)    = robots(r).Kd_eff;
    end

    trash_r_log(end+1,:) = trash_r;
    dist_r_log(end+1,:)  = dist_r;
    cov_r_log(end+1,:)   = cov_r;
    kp_log(end+1,:)      = kp_r;
    ki_log(end+1,:)      = ki_r;
    kd_log(end+1,:)      = kd_r;

    dmag_r = zeros(1,num_robots_total);
    for r = 1:num_robots_total
        dmag_r(r) = robots(r).last_dist_mag;
    end
    dmag_log(end+1,:) = dmag_r;
    wind_log(end+1)   = norm(wind_vec);
    cur_log(end+1)    = norm(cur_vec);
    wave_log(end+1)   = wave_now;

    % ---- position / heading logging ----
    px_r = zeros(1,num_robots_total);  py_r = px_r;  th_r = px_r;
    de_r = px_r;  he_r = px_r;  dh_r = px_r;  td_r = px_r;
    ac_r = false(1,num_robots_total);
    for r = 1:num_robots_total
        px_r(r) = robots(r).x;
        py_r(r) = robots(r).y;
        th_r(r) = atan2(sin(robots(r).theta),cos(robots(r).theta));
        de_r(r) = robots(r).field_angle_last;
        he_r(r) = robots(r).herr_last;
        dh_r(r) = robots(r).dherr_last;
        td_r(r) = robots(r).tdist_last;
        ac_r(r) = ~robots(r).done;
    end
    pos_x_log(end+1,:)   = px_r;
    pos_y_log(end+1,:)   = py_r;
    theta_log(end+1,:)   = th_r;
    desired_log(end+1,:) = de_r;
    herr_log(end+1,:)    = he_r;
    dherr_log(end+1,:)   = dh_r;
    tdist_log(end+1,:)   = td_r;
    active_log(end+1,:)  = ac_r;

    %% ============================================================
    %  LIVE GRAPHICS / STATS
    % ============================================================

    for r=1:num_robots_total

        % Visual heave on the waves (display only; physics uses robots(r).y)
        y_vis = robots(r).y + bob_amp*sin(bob_phase + 0.15*(robots(r).x+robots(r).y));

        set(robots(r).body, ...
            'XData',robots(r).x, ...
            'YData',y_vis);

        set(robots(r).dir, ...
            'XData',robots(r).x, ...
            'YData',y_vis, ...
            'UData',arrow_length*cos(robots(r).theta), ...
            'VData',arrow_length*sin(robots(r).theta));

        if robots(r).task_type==1
            task_name='TRASH';
        elseif robots(r).task_type==2
            task_name='COVER';
        else
            task_name='HOME';
        end

        if robots(r).escape_timer > 0
            task_name = [task_name '*']; %#ok<AGROW> orbit-escape active
        end

        set(robots(r).label,'Position', ...
            [robots(r).x+1,y_vis+1.5], ...
            'String',sprintf('R%d [%s] %.0f%%', ...
            r,task_name,robots(r).battery));
    end

    stats_str=sprintf( ...
        'Env: %s\nTrash: %d/%d\nCoverage: %.1f%%\nTime: %.1fs\nReplans: %d\nNear-misses: %d', ...
        env_name,sum(collected),num_trash, ...
        coverage_percent,sim_time,replan_count,near_miss_count);

    stats_str=[stats_str sprintf('\nDisturb [%s]: wind %.2f  cur %.2f', ...
        dist_choice,norm(wind_vec),norm(cur_vec))];

    for r=1:num_robots_total

        stats_str=sprintf('%s\nR%d: v=%.2f  Bat=%.1f%%  D=%.1f', ...
            stats_str,r,robots(r).v, ...
            robots(r).battery,robots(r).distance);
    end

    set(stats_text,'String',stats_str);

    if norm(wind_vec) > 1e-6
        wdir = wind_vec/norm(wind_vec);
    else
        wdir = [0 0];
    end
    w_len = wind_arrow_len*min(norm(wind_vec)/1.5,1);
    set(wind_arrow,'UData',w_len*wdir(1),'VData',w_len*wdir(2));
    set(wind_text,'String',sprintf('Wind %.2f | Current %.2f', ...
        norm(wind_vec),norm(cur_vec)));

    drawnow limitrate;

    %% ------------------------------------------------------------
    %  STOP CONDITIONS
    % ------------------------------------------------------------

    all_done=all([robots.done]);

    if sim_time>3000
        warning('Maximum simulation time reached.');
        all_done=true;
    end
end

%% ================================================================
%  FINAL RESULTS
%  ================================================================

fprintf('\n====================================================\n');
fprintf('      ADVANCED WATER SURFACE ROBOT RESULTS\n');
fprintf('====================================================\n');

fprintf('Environment:              %s\n',env_name);
fprintf('Heading controller:       %s\n',ctrl_name);
fprintf('Robots:                   %d\n',num_robots_total);
fprintf('Trash collected:         %d/%d\n',sum(collected),num_trash);
fprintf('Collection efficiency:    %.1f%%\n', ...
    100*sum(collected)/num_trash);

fprintf('Mission time:             %.2f s\n',sim_time);
fprintf('Coverage achieved:        %.1f%%\n',coverage_log(end));
fprintf('Task/stuck replans:       %d\n',replan_count);
fprintf('Safety overrides:         %d\n',safety_override_count);
fprintf('Orbit escapes triggered:  %d\n',sum([robots.orbit_events]));
fprintf('Predictive near-misses:   %d\n',near_miss_count);

fprintf('\nBASE PID GAINS (adaptive scheduling around these):\n');
fprintf('  Kp = %.2f  (range %.2f - %.2f)\n',Kp_heading,Kp_min,Kp_max);
fprintf('  Ki = %.2f\n',Ki_heading);
fprintf('  Kd = %.2f  (range %.2f - %.2f)\n',Kd_heading,Kd_min,Kd_max);

fprintf('\nENVIRONMENTAL DISTURBANCES:\n');
fprintf('  Level:            %s (scale %.1f)\n',dist_choice,dist_scale);
fprintf('  Base wind:        [%.2f %.2f]  gust sigma %.2f\n', ...
    wind_base(1),wind_base(2),gust_sigma);
fprintf('  Base current:     [%.2f %.2f]\n',current_base(1),current_base(2));
fprintf('  Wave amp / freq:  %.2f / %.2f Hz\n',wave_amp,wave_freq);
fprintf('  Mean wind speed:  %.2f   Peak: %.2f\n',mean(wind_log),max(wind_log));

fprintf('\nPER-ROBOT METRICS:\n');

for r = 1:num_robots_total
    avg_speed = mean(speed_log(:,r));
    fprintf('--- Robot %d ---\n', r);
    fprintf('  Trash collected:   %d (%.1f%% of total)\n', ...
        robots(r).trash_collected, 100*robots(r).trash_collected/num_trash);
    fprintf('  Distance:          %.2f\n', robots(r).distance);
    fprintf('  Avg speed:         %.2f\n', avg_speed);
    fprintf('  Coverage:          %.1f%%\n', cov_r_log(end,r));
    fprintf('  Battery left:      %.1f%%  (used %.1f)\n', ...
        robots(r).battery, robots(r).energy_used);
    fprintf('  Finish time:       %.1f s\n', robots(r).finish_time);
    fprintf('  Replans:           %d\n', robots(r).replans);
    fprintf('  Safety overrides:  %d\n', robots(r).safety_overrides);
    fprintf('  Orbit escapes:     %d\n', robots(r).orbit_events);
    fprintf('  Near-misses:       %d\n', robots(r).near_misses);
    fprintf('  Mean Kp/Ki/Kd:     %.2f / %.3f / %.2f\n', ...
        mean(kp_log(:,r)), mean(ki_log(:,r)), mean(kd_log(:,r)));
    fprintf('  Mean disturbance:  %.2f  (peak %.2f)\n', ...
        robots(r).dist_mag_sum/max(robots(r).dist_steps,1), ...
        robots(r).dist_mag_max);
    fprintf('  Drift pushed:      %.2f\n', robots(r).drift_distance);
    fprintf('  Ground distance:   %.2f  (commanded %.2f, ratio %.2f)\n', ...
        robots(r).ground_distance, robots(r).distance, ...
        robots(r).ground_distance/max(robots(r).distance,1e-6));
end

fprintf('\nADVANCED FEATURES ENABLED:\n');
fprintf('  [1] Dynamic Task Allocation\n');
fprintf('  [2] Adaptive-Gain PID Heading Control\n');
fprintf('  [3] Adaptive Speed Control\n');
fprintf('  [4] Predictive Obstacle Avoidance\n');
fprintf('  [5] Predictive Inter-Robot Collision Avoidance\n');
fprintf('  [6] Artificial Potential Field Navigation\n');
fprintf('  [7] Battery / Energy Management\n');
fprintf('  [8] Stuck Detection and Recovery\n');
fprintf('  [9] Dynamic Replanning\n');
fprintf(' [10] Coverage Monitoring\n');
fprintf(' [11] Environmental Disturbances (wind/current/waves)\n');

fprintf('====================================================\n');

if is_detail

%% ================================================================
%  ADVANCED PERFORMANCE DASHBOARD (combined)
% ================================================================

figure('Color','white');
set(gcf,'Name','Advanced Robot Control Dashboard');

subplot(2,4,1);
plot(time_log,trash_log,'LineWidth',2);
xlabel('Time (s)');
ylabel('Trash Collected');
title('Dynamic Task / Collection');
grid on;

subplot(2,4,2);
plot(time_log,coverage_log,'LineWidth',2);
xlabel('Time (s)');
ylabel('Coverage (%)');
title('Coverage Monitoring');
grid on;

subplot(2,4,3);
plot(time_log,battery_log,'LineWidth',2);
xlabel('Time (s)');
ylabel('Battery (%)');
title('Battery / Energy Management');
grid on;

subplot(2,4,4);
plot(time_log,speed_log,'LineWidth',2);
xlabel('Time (s)');
ylabel('Speed');
title('Adaptive Speed Control');
grid on;

subplot(2,4,5);
plot(time_log,omega_log,'LineWidth',2);
xlabel('Time (s)');
ylabel('Angular Velocity');
title('PID Heading Control');
grid on;

subplot(2,4,6);
plot(time_log,replan_log,'LineWidth',2); hold on;
plot(time_log,safety_log,'LineWidth',2);
plot(time_log,orbit_log,'LineWidth',2);
xlabel('Time (s)');
ylabel('Event Count');
title('Replanning / Safety / Orbit Escapes');
legend('Task+stuck replans','Safety overrides','Orbit escapes', ...
    'Location','northwest');
grid on;

subplot(2,4,7);
plot(time_log,wind_log,'LineWidth',2); hold on;
plot(time_log,cur_log,'LineWidth',2);
plot(time_log,wave_log,'LineWidth',1);
xlabel('Time (s)');
ylabel('Velocity');
title('Environmental Disturbances');
legend('Wind','Current','Wave','Location','best');
grid on;

subplot(2,4,8); hold on;
for r = 1:num_robots_total
    plot(time_log,dmag_log(:,r),'Color',robot_colors(r,:),'LineWidth',1.5);
end
xlabel('Time (s)');
ylabel('Speed');
title('Disturbance Felt per Robot');
legend(arrayfun(@(k) sprintf('R%d',k),1:num_robots_total, ...
    'UniformOutput',false),'Location','best');
grid on;

%% ================================================================
%  PER-ROBOT METRIC FIGURES (one figure per robot)
% ================================================================

for r = 1:num_robots_total
    figure('Color','white','Name',sprintf('Robot %d Metrics',r));
    c = robot_colors(r,:);

    subplot(3,3,1); plot(time_log,trash_r_log(:,r),'Color',c,'LineWidth',2);
    xlabel('Time (s)'); ylabel('Trash'); title('Trash Collected'); grid on;

    subplot(3,3,2); plot(time_log,cov_r_log(:,r),'Color',c,'LineWidth',2);
    xlabel('Time (s)'); ylabel('%'); title('Coverage'); grid on;

    subplot(3,3,3); plot(time_log,battery_log(:,r),'Color',c,'LineWidth',2);
    xlabel('Time (s)'); ylabel('%'); title('Battery'); grid on;

    subplot(3,3,4); plot(time_log,dist_r_log(:,r),'Color',c,'LineWidth',2);
    xlabel('Time (s)'); ylabel('Distance'); title('Distance Travelled'); grid on;

    subplot(3,3,5); plot(time_log,speed_log(:,r),'Color',c,'LineWidth',2);
    xlabel('Time (s)'); ylabel('Speed'); title('Speed'); grid on;

    subplot(3,3,6); plot(time_log,omega_log(:,r),'Color',c,'LineWidth',2);
    xlabel('Time (s)'); ylabel('\omega'); title('Angular Velocity'); grid on;

    subplot(3,3,7); plot(time_log,kp_log(:,r),'LineWidth',2); hold on;
    plot(time_log,kd_log(:,r),'LineWidth',2);
    plot(time_log,ki_log(:,r),'LineWidth',2);
    xlabel('Time (s)'); ylabel('Gain'); title('Adaptive PID Gains');
    legend('Kp','Kd','Ki','Location','best'); grid on;

    subplot(3,3,8);
    bar([robots(r).replans robots(r).safety_overrides ...
         robots(r).orbit_events robots(r).near_misses],'FaceColor',c);
    set(gca,'XTickLabel',{'Replans','Safety','Orbit','NearMiss'});
    title('Event Counts');

    subplot(3,3,9); plot(time_log,dmag_log(:,r),'Color',c,'LineWidth',2);
    xlabel('Time (s)'); ylabel('Speed'); title('Disturbance Experienced'); grid on;
end

end   % if is_detail (dashboards)

%% ================================================================
%  PACKAGE THIS RUN'S DATA, THEN DRAW POSITION / HEADING / STABILITY
%  ================================================================

S = struct();
S.ctrl_id   = ctrl_id;      S.ctrl_name = ctrl_name;   S.env_name = env_name;
S.N         = num_robots_total;   S.dt = dt;
S.t         = time_log(:);
S.pos_x     = pos_x_log;    S.pos_y   = pos_y_log;
S.theta     = theta_log;    S.desired = desired_log;
S.herr      = herr_log;     S.dherr   = dherr_log;
S.omega     = omega_log;    S.speed   = speed_log;
S.kp        = kp_log;       S.ki = ki_log;   S.kd = kd_log;
S.tdist     = tdist_log;    S.active  = active_log;
S.colors    = robot_colors(1:num_robots_total,:);
S.boundary  = boundary;     S.home = home_base;
S.xlim      = xlim_range;   S.ylim = ylim_range;
S.coll      = coll_pos;     S.obstacles = obstacles;
S.mission_time = sim_time;  S.trash = sum(collected);  S.num_trash = num_trash;
S.distance  = [robots.distance];
S.energy    = [robots.energy_used];
S.safety    = safety_override_count;
S.orbit     = sum([robots.orbit_events]);
S.near      = near_miss_count;
S = controller_metrics(S);
cmp_runs{run_k} = S;

if is_detail
    plot_position_graphs(S);          % POSITION GRAPHS
    plot_heading_graphs(S);           % HEADING ANGLE VALUES + graphs
    plot_stability_graphs({S});       % STABILITY GRAPHS
    fprintf('Stability (%s): max spectral radius = %.4f, stable %.1f%% of the time\n', ...
        ctrl_name, S.m_rho_max, S.m_stable_pct);
end

if ~is_detail && ishandle(live_fig)
    close(live_fig);                  % keep only the selected controller's live view
end

end   % ---- end of RUN LOOP ----

%% ================================================================
%  CONTROLLER COMPARISON (only when "Compare all controllers" is ticked)
%  ================================================================

if compare_mode
    plot_controller_comparison(cmp_runs);
end

%% ================================================================
%  LOCAL HELPER FUNCTIONS
%  (MATLAB requires local functions to be placed at the end of a
%   script file.)
% ================================================================

function [min_dist, nearest_point] = distance_to_polygon_boundary(px, py, poly)
% DISTANCE_TO_POLYGON_BOUNDARY  Shortest distance from the point
% (px,py) to the polygon's EDGES (the actual shoreline shape), plus the
% closest point on that boundary. This is different from just checking
% inpolygon() -- a point can be well inside the polygon by area but
% still be right next to a concave notch in the shoreline, which
% inpolygon() alone would not reveal.

    n = size(poly, 1);
    min_dist = inf;
    nearest_point = [px py];

    for e = 1:n
        a = poly(e, :);
        if e < n
            b = poly(e+1, :);
        else
            b = poly(1, :);
        end

        ab = b - a;
        ab_len2 = dot(ab, ab);

        if ab_len2 < 1e-9
            t = 0;
        else
            t = dot([px py] - a, ab) / ab_len2;
            t = max(0, min(1, t));
        end

        proj = a + t * ab;
        d = norm([px py] - proj);

        if d < min_dist
            min_dist = d;
            nearest_point = proj;
        end
    end
end

function ok = is_position_safe(px, py, boundary, obstacles)
% IS_POSITION_SAFE  True if (px,py) is inside the water boundary polygon
% AND clear of every obstacle by its safety margin. Used by the final
% safety check (and its reduced-step fallback) so the same rule is
% applied consistently everywhere motion is validated.

    ok = inpolygon(px, py, boundary(:,1), boundary(:,2));

    if ~ok
        return;
    end

    for k = 1:size(obstacles, 1)
        obs = obstacles(k, :);

        if obs(3) == 1
            clearance = obs(4) + 1.5;
        elseif obs(3) == 2
            clearance = max(obs(4), obs(5)) + 1.5;
        else
            clearance = obs(4) + 1.5;
        end

        if norm([px py] - obs(1:2)) < clearance
            ok = false;
            return;
        end
    end
end

function d = disturbance_at(px, py, env)
% DISTURBANCE_AT  Environmental drift velocity [dx dy] at (px,py).
%   wind    : steady + gust vector, scaled by 'windage'
%   current : steady flow; in the River it follows a mid-channel profile
%             (fastest in the middle, slower near the banks)
%   waves   : sinusoidal push perpendicular to the wind direction, with a
%             small spatial phase offset so different positions are not
%             pushed in perfect lockstep

    cur = env.cur;

    if env.river
        half = (env.ymax - env.ymin)/2;
        ymid = (env.ymax + env.ymin)/2;
        prof = 0.4 + 0.6*max(0, 1 - ((py - ymid)/half)^2);
        cur  = env.cur * prof;
    end

    wspd = norm(env.wind);
    if wspd > 1e-6
        perp = [-env.wind(2) env.wind(1)]/wspd;
    else
        perp = [0 1];
    end

    wave = env.wave_amp * sin(2*pi*env.wave_freq*env.t + 0.15*(px+py)) * perp;

    d = env.windage*env.wind + cur + wave;
end

function d = disturbance_field(px, py, env)
% DISTURBANCE_FIELD  Vectorised version of disturbance_at() used by the
% water-flow particles. px, py are column vectors; returns an n-by-2 array
% of drift velocities [dx dy] using exactly the same wind / current / wave
% model the robots feel, so the visible flow matches the physics.

    n = numel(px);
    px = px(:);  py = py(:);

    cur = repmat(env.cur, n, 1);
    if env.river
        half = (env.ymax - env.ymin)/2;
        ymid = (env.ymax + env.ymin)/2;
        prof = 0.4 + 0.6*max(0, 1 - ((py - ymid)/half).^2);
        cur  = prof .* env.cur;
    end

    wspd = norm(env.wind);
    if wspd > 1e-6
        perp = [-env.wind(2) env.wind(1)]/wspd;
    else
        perp = [0 1];
    end

    wave = env.wave_amp * sin(2*pi*env.wave_freq*env.t + 0.15*(px+py)) .* perp;

    d = env.windage*env.wind + cur + wave;
end

function pts = spawn_in_poly(n, poly, xl, yl)
% SPAWN_IN_POLY  n random points inside the water polygon (rejection sampling).

    pts = zeros(n,2);
    filled = 0;
    tries  = 0;

    while filled < n && tries < 200
        m    = max(2*(n-filled), 10);
        cand = [xl(1)+diff(xl)*rand(m,1), yl(1)+diff(yl)*rand(m,1)];
        ok   = inpolygon(cand(:,1),cand(:,2),poly(:,1),poly(:,2));
        cand = cand(ok,:);
        k    = min(size(cand,1), n-filled);
        pts(filled+1:filled+k,:) = cand(1:k,:);
        filled = filled + k;
        tries  = tries + 1;
    end

    if filled < n
        pts(filled+1:end,:) = repmat(mean(poly,1), n-filled, 1);
    end
end

%% ================================================================
%  CONTROLLER ANALYSIS / PLOTTING FUNCTIONS (added)
%  Position graphs, heading-angle values, controller comparison and
%  stability analysis. Uses the data logged by the main loop.
%
%  STABILITY MODEL: the heading loop is  theta(k+1) = theta(k) + dt*omega(k)
%  with omega = Kp*e + Ki*dt*sum(e) + Kd*(e(k)-e(k-1))/dt. Its closed-loop
%  characteristic polynomial (target held fixed) is
%     z^3 + (-2+dt*Kp+Ki*dt^2+Kd) z^2 + (1-dt*Kp-2*Kd) z + Kd = 0   (Ki > 0)
%     z^2 + (-1+dt*Kp+Kd) z - Kd = 0                                (Ki = 0)
%  The loop is stable when every root lies inside the unit circle
%  (spectral radius rho < 1). This is a local linear analysis: the real
%  loop also has the omega saturation and the moving target.
% ================================================================

function S = controller_metrics(S)
    N = S.N;  dt = S.dt;  T = numel(S.t);

    S.m_rms = zeros(1,N);   S.m_meanabs = zeros(1,N);  S.m_max = zeros(1,N);
    S.m_std = zeros(1,N);   S.m_itae = zeros(1,N);     S.m_effort = zeros(1,N);
    S.m_smooth = zeros(1,N); S.m_meanhead = zeros(1,N); S.m_finalhead = zeros(1,N);
    S.m_meanomega = zeros(1,N);

    for r = 1:N
        a = S.active(:,r);
        if nnz(a) < 3, a = true(T,1); end

        e  = S.herr(a,r)*180/pi;
        om = S.omega(a,r);
        tt = S.t(a);

        S.m_rms(r)       = sqrt(mean(e.^2));
        S.m_meanabs(r)   = mean(abs(e));
        S.m_max(r)       = max(abs(e));
        S.m_std(r)       = std(e);
        S.m_itae(r)      = sum(tt.*abs(e*pi/180))*dt;
        S.m_effort(r)    = sum(om.^2)*dt;
        S.m_smooth(r)    = mean(abs(diff(om)));
        S.m_meanomega(r) = mean(abs(om));
        S.m_meanhead(r)  = atan2(mean(sin(S.theta(a,r))),mean(cos(S.theta(a,r))))*180/pi;
        S.m_finalhead(r) = S.theta(find(a,1,'last'),r)*180/pi;
    end

    % ---- stability of the linearised sampled loop along the run ----
    stride = max(1, ceil(T/1500));
    S.rho_idx = (1:stride:T)';
    S.rho = zeros(numel(S.rho_idx), N);
    for r = 1:N
        for q = 1:numel(S.rho_idx)
            k = S.rho_idx(q);
            S.rho(q,r) = loop_rho(S.kp(k,r),S.ki(k,r),S.kd(k,r),dt);
        end
    end
    S.m_rho_max    = max(S.rho(:));
    S.m_stable_pct = 100*mean(S.rho(:) < 1);
end

function p = loop_poles(Kp, Ki, Kd, dt)
    if Ki < 1e-9
        c = [1, -1+dt*Kp+Kd, -Kd];
    else
        c = [1, -2+dt*Kp+Ki*dt^2+Kd, 1-dt*Kp-2*Kd, Kd];
    end
    p = roots(c);
end

function rho = loop_rho(Kp, Ki, Kd, dt)
    rho = max(abs(loop_poles(Kp,Ki,Kd,dt)));
end

function [w, magdb, ph, pm, gm] = loop_bode(Kp, Ki, Kd, dt)
% Frequency response of the sampled open loop L(z) = dt*C(z)/(z-1).
    w = logspace(-2, log10(pi/dt)-1e-3, 600);
    z = exp(1i*w*dt);
    C = Kp + Ki*dt*z./(z-1) + Kd*(z-1)./(dt*z);
    L = dt*C./(z-1);

    mag   = abs(L);
    magdb = 20*log10(mag);
    ph    = unwrap(angle(L))*180/pi;

    pm = NaN;  gm = Inf;
    k = find(diff(sign(mag-1)) ~= 0, 1, 'last');
    if ~isempty(k), pm = 180 + ph(k); end
    j = find(diff(sign(ph+180)) ~= 0, 1, 'first');
    if ~isempty(j), gm = -magdb(j); end
end

function y = break_wrap(y)
% Insert NaN at +-180 deg wrap jumps so lines don't draw vertical strokes.
    y = y(:);
    jump = [false; abs(diff(y)) > 180];
    y(jump) = NaN;
end

function draw_paths(ax, S)
% Draw boundary, obstacles, robot paths, start/end markers, trash pick-ups.
    hold(ax,'on');
    patch('Parent',ax,'XData',S.boundary(:,1),'YData',S.boundary(:,2), ...
        'FaceColor',[0.75 0.88 1],'FaceAlpha',0.6,'EdgeColor','b','LineWidth',1.5);

    th = linspace(0,2*pi,40);
    for k = 1:size(S.obstacles,1)
        ob = S.obstacles(k,:);
        if ob(3)==2, rr = max(ob(4),ob(5)); else, rr = ob(4); end
        patch('Parent',ax,'XData',ob(1)+rr*cos(th),'YData',ob(2)+rr*sin(th), ...
            'FaceColor',[0.5 0.5 0.5],'FaceAlpha',0.5,'EdgeColor','k');
    end

    hl = gobjects(S.N,1);
    for r = 1:S.N
        hl(r) = plot(ax,S.pos_x(:,r),S.pos_y(:,r),'-', ...
            'Color',S.colors(r,:),'LineWidth',1.3);
        plot(ax,S.pos_x(1,r),S.pos_y(1,r),'o','MarkerFaceColor',S.colors(r,:), ...
            'MarkerEdgeColor','k','MarkerSize',7);
        plot(ax,S.pos_x(end,r),S.pos_y(end,r),'s','MarkerFaceColor',S.colors(r,:), ...
            'MarkerEdgeColor','k','MarkerSize',7);
    end

    if ~isempty(S.coll)
        plot(ax,S.coll(:,1),S.coll(:,2),'kx','MarkerSize',6);
    end
    plot(ax,S.home(1),S.home(2),'kp','MarkerSize',12,'MarkerFaceColor','y');

    axis(ax,'equal');  xlim(ax,S.xlim);  ylim(ax,S.ylim);
    grid(ax,'on');  xlabel(ax,'x');  ylabel(ax,'y');
    legend(ax,hl,arrayfun(@(k) sprintf('R%d',k),1:S.N,'UniformOutput',false), ...
        'Location','best');
end

function plot_position_graphs(S)
% POSITION GRAPHS: x-y paths, x(t), y(t) and distance to the current target.
    N = S.N;
    names = arrayfun(@(k) sprintf('R%d',k),1:N,'UniformOutput',false);

    figure('Color','w','Name',sprintf('Position Graphs - %s',S.ctrl_name), ...
        'NumberTitle','off');

    ax1 = subplot(2,2,1);
    draw_paths(ax1,S);
    title(sprintf('Robot paths (o start, s end, x pick-up) - %s',S.ctrl_name));

    subplot(2,2,2); hold on;
    for r = 1:N, plot(S.t,S.pos_x(:,r),'Color',S.colors(r,:),'LineWidth',1.5); end
    xlabel('Time (s)'); ylabel('x position'); title('X position vs time');
    legend(names,'Location','best'); grid on;

    subplot(2,2,3); hold on;
    for r = 1:N, plot(S.t,S.pos_y(:,r),'Color',S.colors(r,:),'LineWidth',1.5); end
    xlabel('Time (s)'); ylabel('y position'); title('Y position vs time');
    legend(names,'Location','best'); grid on;

    subplot(2,2,4); hold on;
    for r = 1:N, plot(S.t,S.tdist(:,r),'Color',S.colors(r,:),'LineWidth',1.3); end
    xlabel('Time (s)'); ylabel('Distance to target'); title('Position error to current target');
    legend(names,'Location','best'); grid on;
end

function plot_heading_graphs(S)
% HEADING GRAPHS + VALUES: heading vs desired, error, error histogram,
% moving RMS error, a values table, console print and CSV export.
    N = S.N;  dt = S.dt;
    names = arrayfun(@(k) sprintf('R%d',k),1:N,'UniformOutput',false);

    figure('Color','w','Name',sprintf('Heading Angle - %s',S.ctrl_name), ...
        'NumberTitle','off');

    subplot(2,2,1); hold on;  h = gobjects(N,1);
    for r = 1:N
        a = S.active(:,r);  if nnz(a) < 3, a = true(size(a)); end
        plot(S.t(a),break_wrap(S.desired(a,r)*180/pi),':','Color',S.colors(r,:),'LineWidth',1);
        h(r) = plot(S.t(a),break_wrap(S.theta(a,r)*180/pi),'-','Color',S.colors(r,:),'LineWidth',1.4);
    end
    xlabel('Time (s)'); ylabel('Heading (deg)');
    title('Heading angle (solid) vs desired (dotted)');
    legend(h,names,'Location','best'); grid on; ylim([-185 185]);

    subplot(2,2,2); hold on;
    for r = 1:N
        a = S.active(:,r);  if nnz(a) < 3, a = true(size(a)); end
        plot(S.t(a),S.herr(a,r)*180/pi,'Color',S.colors(r,:),'LineWidth',1.2);
    end
    xlabel('Time (s)'); ylabel('Error (deg)'); title('Heading error'); 
    legend(names,'Location','best'); grid on;

    subplot(2,2,3); hold on;
    for r = 1:N
        a = S.active(:,r);  if nnz(a) < 3, a = true(size(a)); end
        histogram(S.herr(a,r)*180/pi,40,'Normalization','pdf', ...
            'FaceColor',S.colors(r,:),'FaceAlpha',0.4,'EdgeColor','none');
    end
    xlabel('Heading error (deg)'); ylabel('Probability density');
    title('Heading error distribution'); legend(names,'Location','best'); grid on;

    subplot(2,2,4); hold on;
    win = max(3, round(5/dt));
    for r = 1:N
        e = S.herr(:,r)*180/pi;  e(~S.active(:,r)) = NaN;
        plot(S.t,sqrt(movmean(e.^2,win,'omitnan')),'Color',S.colors(r,:),'LineWidth',1.5);
    end
    xlabel('Time (s)'); ylabel('RMS error (deg)'); title('Moving RMS heading error (5 s window)');
    legend(names,'Location','best'); grid on;

    % ---------- values table ----------
    vals = zeros(N,8);
    for r = 1:N
        vals(r,:) = [r, S.m_meanhead(r), S.m_finalhead(r), S.m_meanabs(r), ...
                     S.m_rms(r), S.m_max(r), S.m_std(r), S.m_meanomega(r)];
    end
    cols = {'Robot','Mean heading (deg)','Final heading (deg)','Mean |err| (deg)', ...
            'RMS err (deg)','Max |err| (deg)','Std err (deg)','Mean |omega| (rad/s)'};

    f2 = figure('Color','w','Name',sprintf('Heading Angle Values - %s',S.ctrl_name), ...
        'NumberTitle','off','Position',[200 200 980 70+32*N]);
    uitable('Parent',f2,'Units','normalized','Position',[0.01 0.03 0.98 0.94], ...
        'Data',vals,'ColumnName',cols,'RowName',[], ...
        'ColumnWidth',{50,115,115,105,100,105,100,125});

    fprintf('\nHEADING ANGLE VALUES  (%s)\n',S.ctrl_name);
    fprintf('%6s %12s %12s %11s %10s %11s %10s %12s\n','Robot','MeanHead','FinalHead', ...
        'Mean|err|','RMSerr','Max|err|','Stderr','Mean|omega|');
    for r = 1:N
        fprintf('%6d %12.2f %12.2f %11.3f %10.3f %11.3f %10.3f %12.4f\n',vals(r,:));
    end

    % ---------- CSV export of every logged heading value ----------
    fn  = sprintf('heading_values_%s_%s.csv',S.env_name,strrep(S.ctrl_name,' ','_'));
    hdr = 'time_s';
    M   = S.t;
    for r = 1:N
        hdr = [hdr sprintf(',R%d_heading_deg,R%d_desired_deg,R%d_error_deg',r,r,r)]; %#ok<AGROW>
        M   = [M, S.theta(:,r)*180/pi, S.desired(:,r)*180/pi, S.herr(:,r)*180/pi]; %#ok<AGROW>
    end
    try
        fid = fopen(fn,'w');  fprintf(fid,'%s\n',hdr);  fclose(fid);
        dlmwrite(fn,M,'-append','precision','%.5f');
        fprintf('Heading values saved to %s\n',fn);
    catch
        warning('Could not write %s',fn);
    end
end

function plot_stability_graphs(runs)
% STABILITY GRAPHS: Lyapunov function, phase portrait, closed-loop poles
% on the z-plane, spectral radius over time, Bode magnitude and phase.
    multi = numel(runs) > 1;
    cc = [0 0.45 0.74; 0.85 0.33 0.10; 0.47 0.67 0.19; 0.49 0.18 0.56];

    if multi
        ttl = 'Stability Analysis - controller comparison';
    else
        ttl = sprintf('Stability Analysis - %s',runs{1}.ctrl_name);
    end
    figure('Color','w','Name',ttl,'NumberTitle','off');

    a1 = subplot(2,3,1); hold(a1,'on'); set(a1,'YScale','log');
    a2 = subplot(2,3,2); hold(a2,'on');
    a3 = subplot(2,3,3); hold(a3,'on');
    a4 = subplot(2,3,4); hold(a4,'on');
    a5 = subplot(2,3,5); hold(a5,'on'); set(a5,'XScale','log');
    a6 = subplot(2,3,6); hold(a6,'on'); set(a6,'XScale','log');

    th = linspace(0,2*pi,200);
    plot(a3,cos(th),sin(th),'k-','LineWidth',1);
    plot(a3,[-1.3 1.3],[0 0],'k:');  plot(a3,[0 0],[-1.3 1.3],'k:');

    h1 = gobjects(0);  l1 = {};
    h4 = gobjects(0);  l4 = {};
    h5 = gobjects(0);  l5 = {};
    allD = [];

    for i = 1:numel(runs)
        S = runs{i};
        N = S.N;  dt = S.dt;
        win = max(3, round(5/dt));

        if multi
            cols = repmat(cc(S.ctrl_id,:),N,1);
        else
            cols = S.colors;
        end

        % ---- (1) Lyapunov function V = 0.5 e^2 ----
        V = 0.5*S.herr.^2;  V(~S.active) = NaN;
        if multi
            Vm = movmean(mean(V,2,'omitnan'),win,'omitnan');
            h = plot(a1,S.t,Vm+1e-9,'Color',cols(1,:),'LineWidth',1.6);
            h1(end+1) = h;  l1{end+1} = S.ctrl_name; %#ok<AGROW>
        else
            for r = 1:N
                Vr = movmean(V(:,r),win,'omitnan');
                h = plot(a1,S.t,Vr+1e-9,'Color',cols(r,:),'LineWidth',1.4);
                h1(end+1) = h;  l1{end+1} = sprintf('R%d',r); %#ok<AGROW>
            end
        end

        % ---- (2) phase portrait e vs de/dt ----
        for r = 1:N
            a = S.active(:,r);
            if nnz(a) < 3, continue; end
            e = S.herr(a,r)*180/pi;
            d = S.dherr(a,r)*180/pi;
            k = unique(round(linspace(1,numel(e),min(1500,numel(e)))));
            plot(a2,e(k),d(k),'.','Color',cols(r,:),'MarkerSize',4);
            allD = [allD; d(k)]; %#ok<AGROW>
        end

        % ---- (3) closed-loop poles on the z-plane ----
        for r = 1:N
            qi = unique(round(linspace(1,numel(S.rho_idx),min(120,numel(S.rho_idx)))));
            for q = qi
                kk = S.rho_idx(q);
                p = loop_poles(S.kp(kk,r),S.ki(kk,r),S.kd(kk,r),dt);
                plot(a3,real(p),imag(p),'x','Color',cols(r,:),'MarkerSize',4);
            end
        end

        % ---- (4) spectral radius over time ----
        tr_ = S.t(S.rho_idx);
        if multi
            h = plot(a4,tr_,mean(S.rho,2),'Color',cols(1,:),'LineWidth',1.6);
            h4(end+1) = h; %#ok<AGROW>
            l4{end+1} = sprintf('%s (%.0f%% stable)',S.ctrl_name,S.m_stable_pct); %#ok<AGROW>
        else
            for r = 1:N
                h = plot(a4,tr_,S.rho(:,r),'Color',cols(r,:),'LineWidth',1.4);
                h4(end+1) = h;  l4{end+1} = sprintf('R%d',r); %#ok<AGROW>
            end
        end

        % ---- (5)(6) Bode of the sampled open loop at mean gains ----
        A = S.active;
        if ~any(A(:)), A = true(size(A)); end
        Kp_m = mean(S.kp(A));  Ki_m = mean(S.ki(A));  Kd_m = mean(S.kd(A));
        [w,mdb,ph,pm,~] = loop_bode(Kp_m,Ki_m,Kd_m,dt);

        if multi
            c = cc(S.ctrl_id,:);
            lbl = sprintf('%s (PM %.0f deg)',S.ctrl_name,pm);
        else
            c = [0 0 0];
            lbl = sprintf('Mean gains (PM %.0f deg)',pm);
        end
        h = plot(a5,w,mdb,'Color',c,'LineWidth',1.6);
        h5(end+1) = h;  l5{end+1} = lbl; %#ok<AGROW>
        plot(a6,w,ph,'Color',c,'LineWidth',1.6);
    end

    % ---- decorations ----
    xlabel(a1,'Time (s)'); ylabel(a1,'V = 0.5 e^2  (rad^2)');
    title(a1,'Lyapunov function (decays = stable)'); grid(a1,'on');
    legend(a1,h1,l1,'Location','best');

    xlabel(a2,'Heading error (deg)'); ylabel(a2,'d(error)/dt (deg/s)');
    title(a2,'Phase portrait (error vs rate)'); grid(a2,'on');
    xlim(a2,[-180 180]);
    if ~isempty(allD)
        ylim(a2,[-1 1]*max(3*std(allD),1));
    end
    plot(a2,0,0,'k+','MarkerSize',10,'LineWidth',1.5);

    axis(a3,'equal'); xlim(a3,[-1.3 1.3]); ylim(a3,[-1.3 1.3]);
    xlabel(a3,'Real'); ylabel(a3,'Imag');
    title(a3,'Closed-loop poles, z-plane (inside circle = stable)'); grid(a3,'on');

    xl = get(a4,'XLim');
    plot(a4,xl,[1 1],'r--','LineWidth',1.2);
    xlabel(a4,'Time (s)'); ylabel(a4,'Spectral radius \rho');
    title(a4,'Spectral radius (\rho < 1 = stable)'); grid(a4,'on');
    legend(a4,h4,l4,'Location','best');

    xl = get(a5,'XLim');
    plot(a5,xl,[0 0],'r--');
    xlabel(a5,'Frequency (rad/s)'); ylabel(a5,'Magnitude (dB)');
    title(a5,'Open-loop Bode: magnitude'); grid(a5,'on');
    legend(a5,h5,l5,'Location','best');

    xl = get(a6,'XLim');
    plot(a6,xl,[-180 -180],'r--');
    xlabel(a6,'Frequency (rad/s)'); ylabel(a6,'Phase (deg)');
    title(a6,'Open-loop Bode: phase (PM = distance above -180)'); grid(a6,'on');
end

function plot_controller_comparison(runs)
% Side-by-side comparison of every controller run on the same mission.
    n   = numel(runs);
    cc  = [0 0.45 0.74; 0.85 0.33 0.10; 0.47 0.67 0.19; 0.49 0.18 0.56];
    ids = cellfun(@(s) s.ctrl_id, runs);
    names = cellfun(@(s) s.ctrl_name, runs, 'UniformOutput', false);

    mt  = cellfun(@(s) s.mission_time, runs);
    tr  = cellfun(@(s) s.trash, runs);
    ds  = cellfun(@(s) sum(s.distance), runs);
    en  = cellfun(@(s) sum(s.energy), runs);
    rm  = cellfun(@(s) mean(s.m_rms), runs);
    mx  = cellfun(@(s) max(s.m_max), runs);
    ef  = cellfun(@(s) sum(s.m_effort), runs);
    sm  = cellfun(@(s) mean(s.m_smooth), runs);
    it  = cellfun(@(s) sum(s.m_itae), runs);
    so  = cellfun(@(s) s.safety, runs);
    rhm = cellfun(@(s) s.m_rho_max, runs);
    stp = cellfun(@(s) s.m_stable_pct, runs);

    % ---------- console table ----------
    fprintf('\n====================================================================================================\n');
    fprintf('                              CONTROLLER COMPARISON (same mission)\n');
    fprintf('====================================================================================================\n');
    fprintf('%-16s %8s %6s %9s %8s %9s %9s %9s %9s %8s %6s %7s\n', ...
        'Controller','Time(s)','Trash','Dist','Energy','RMSerr','MaxErr','Effort','Smooth','rhoMax','Stab%','Safety');
    for i = 1:n
        fprintf('%-16s %8.1f %6d %9.1f %8.2f %9.3f %9.2f %9.3f %9.4f %8.4f %6.1f %7d\n', ...
            names{i},mt(i),tr(i),ds(i),en(i),rm(i),mx(i),ef(i),sm(i),rhm(i),stp(i),so(i));
    end
    fprintf('(RMSerr/MaxErr in deg, Effort = sum(omega^2)dt, Smooth = mean|d omega|, Stab%% = time with rho<1)\n');

    % ---------- figure 1: trajectories ----------
    figure('Color','w','Name','Controller Comparison - Trajectories','NumberTitle','off');
    for i = 1:n
        ax = subplot(2,2,i);
        draw_paths(ax,runs{i});
        title(sprintf('%s  (%.0f s, %d trash)',names{i},mt(i),tr(i)));
    end

    % ---------- figure 2: heading comparison ----------
    figure('Color','w','Name','Controller Comparison - Heading','NumberTitle','off');
    tmax = min(60, min(cellfun(@(s) s.t(end), runs)));

    subplot(2,2,1); hold on;  h = gobjects(n,1);
    for i = 1:n
        S = runs{i};  m = S.t <= tmax;
        h(i) = plot(S.t(m),break_wrap(S.theta(m,1)*180/pi),'Color',cc(ids(i),:),'LineWidth',1.4);
    end
    xlabel('Time (s)'); ylabel('Heading (deg)'); title('Robot 1 heading angle (first 60 s)');
    legend(h,names,'Location','best'); grid on;

    subplot(2,2,2); hold on;
    for i = 1:n
        S = runs{i};  m = S.t <= tmax;
        plot(S.t(m),S.herr(m,1)*180/pi,'Color',cc(ids(i),:),'LineWidth',1.3);
    end
    xlabel('Time (s)'); ylabel('Error (deg)'); title('Robot 1 heading error (first 60 s)');
    legend(names,'Location','best'); grid on;

    subplot(2,2,3); hold on;
    for i = 1:n
        S = runs{i};  m = S.t <= tmax;
        plot(S.t(m),S.omega(m,1),'Color',cc(ids(i),:),'LineWidth',1.3);
    end
    xlabel('Time (s)'); ylabel('\omega (rad/s)'); title('Robot 1 control output (first 60 s)');
    legend(names,'Location','best'); grid on;

    subplot(2,2,4); hold on;
    for i = 1:n
        S = runs{i};  win = max(3,round(5/S.dt));
        e = S.herr*180/pi;  e(~S.active) = NaN;
        plot(S.t,sqrt(movmean(mean(e.^2,2,'omitnan'),win,'omitnan')),'Color',cc(ids(i),:),'LineWidth',1.5);
    end
    xlabel('Time (s)'); ylabel('RMS error (deg)'); title('Fleet RMS heading error (5 s window)');
    legend(names,'Location','best'); grid on;

    % ---------- figure 3: metric bars ----------
    figure('Color','w','Name','Controller Comparison - Metrics','NumberTitle','off');
    data   = {mt, tr, ds, en, rm, ef, sm, so};
    titles = {'Mission time (s)','Trash collected','Total distance','Energy used', ...
              'RMS heading error (deg)','Control effort \Sigma\omega^2 dt', ...
              'Smoothness mean|\Delta\omega|','Safety overrides'};
    for k = 1:8
        subplot(2,4,k);
        b = bar(1:n,data{k},'FaceColor','flat');
        b.CData = cc(ids,:);
        set(gca,'XTick',1:n,'XTickLabel',names,'XTickLabelRotation',25);
        title(titles{k}); grid on;
    end

    % ---------- figure 4: stability comparison ----------
    plot_stability_graphs(runs);
end

function s = ternary_str(cond, a, b)
    if cond, s = a; else, s = b; end
end

%% ================================================================
%  LAUNCHER INTERFACE (added) -- interface only, no simulation logic.
%  Collects: environment, number of robots, robot speeds, disturbance
%  level, and hands them to the simulation exactly like the old dialogs.
% ================================================================

function cfg = launch_config_ui()
% LAUNCH_CONFIG_UI  Full-screen control panel that replaces the separate
% listdlg / inputdlg / questdlg pop-ups. Every control is positioned in
% NORMALIZED units (fractions of the window), including fonts, so it fits
% any screen size / display scaling. Closing the window without pressing
% Start gives the same defaults the old dialogs used.

    cfg = struct('env_name','Lake','num_robots',1, ...
                 'speeds',4*ones(1,5),'dist_choice','Moderate', ...
                 'controller',1,'compare',false);

    envs   = {'Lake','Pond','Pool','River','Ocean'};
    colors = [1 0 0; 0 0.7 0; 0 0.1 1; 1 0.5 0; 0.6 0 0.8];
    navy   = [0.05 0.20 0.38];
    paper  = [0.95 0.97 1.00];

    fig = figure('Name','Autonomous Water Surface Cleaning','NumberTitle','off', ...
        'MenuBar','none','ToolBar','none','Color',paper,'Units','normalized', ...
        'Position',[0.04 0.06 0.92 0.86],'Resize','on');
    try, set(fig,'WindowState','maximized'); catch, end
    set(fig,'CloseRequestFcn',@(~,~) uiresume(fig));

    % ---------- header ----------
    uicontrol(fig,'Style','text','Units','normalized','Position',[0 0.89 1 0.11], ...
        'BackgroundColor',navy);
    uicontrol(fig,'Style','text','Units','normalized','Position',[0.02 0.935 0.80 0.055], ...
        'String','Autonomous Water Surface Cleaning','FontUnits','normalized', ...
        'FontSize',0.72,'FontWeight','bold','ForegroundColor','w', ...
        'BackgroundColor',navy,'HorizontalAlignment','left');
    uicontrol(fig,'Style','text','Units','normalized','Position',[0.02 0.897 0.80 0.034], ...
        'String','Multi-robot trash collection  |  adaptive PID  |  obstacle avoidance  |  disturbances', ...
        'FontUnits','normalized','FontSize',0.62,'ForegroundColor',[0.75 0.88 1], ...
        'BackgroundColor',navy,'HorizontalAlignment','left');

    % ---------- 1. environment ----------
    p1 = uipanel(fig,'Units','normalized','Position',[0.02 0.35 0.46 0.52], ...
        'BackgroundColor','w','BorderType','line','HighlightColor',[0.6 0.7 0.8]);
    mk(p1,'text',[0.03 0.91 0.60 0.07],'1   Environment', ...
        'FontSize',0.62,'FontWeight','bold','ForegroundColor',navy);
    mk(p1,'text',[0.03 0.82 0.20 0.055],'Water body:','FontSize',0.62);
    ddEnv = mk(p1,'popupmenu',[0.24 0.815 0.45 0.07],envs,'FontSize',0.55);
    ax = axes('Parent',p1,'Units','normalized','Position',[0.05 0.19 0.90 0.60], ...
        'Box','on','XTick',[],'YTick',[]);
    lblDesc = mk(p1,'text',[0.03 0.095 0.94 0.06],'','FontSize',0.62, ...
        'FontWeight','bold','ForegroundColor',navy);
    lblInfo = mk(p1,'text',[0.03 0.025 0.94 0.05],'','FontSize',0.60, ...
        'ForegroundColor',[0.3 0.3 0.3]);

    % ---------- 2. robots ----------
    p2 = uipanel(fig,'Units','normalized','Position',[0.50 0.42 0.48 0.45], ...
        'BackgroundColor','w','BorderType','line','HighlightColor',[0.6 0.7 0.8]);
    mk(p2,'text',[0.03 0.90 0.60 0.08],'2   Robot fleet', ...
        'FontSize',0.62,'FontWeight','bold','ForegroundColor',navy);
    mk(p2,'text',[0.03 0.78 0.42 0.07],'Number of robots (1-5):','FontSize',0.62);
    spN = mk(p2,'popupmenu',[0.46 0.775 0.14 0.09],{'1','2','3','4','5'},'FontSize',0.55);

    sw = gobjects(5,1);  sld = gobjects(5,1);  val = gobjects(5,1);  nm = gobjects(5,1);
    for r = 1:5
        y = 0.64 - (r-1)*0.135;
        sw(r)  = uicontrol(p2,'Style','text','Units','normalized', ...
            'Position',[0.04 y+0.015 0.03 0.07],'BackgroundColor',colors(r,:));
        nm(r)  = mk(p2,'text',[0.09 y 0.15 0.085],sprintf('Robot %d',r),'FontSize',0.60);
        sld(r) = uicontrol(p2,'Style','slider','Units','normalized', ...
            'Position',[0.26 y+0.01 0.52 0.07],'Min',1,'Max',10,'Value',4, ...
            'SliderStep',[0.1/0.9*0.1 0.1]);
        val(r) = mk(p2,'text',[0.80 y 0.18 0.085],'4.0 u/s','FontSize',0.60, ...
            'FontWeight','bold');
    end

    % ---------- 3. disturbances ----------
    p3 = uipanel(fig,'Units','normalized','Position',[0.50 0.20 0.48 0.20], ...
        'BackgroundColor','w','BorderType','line','HighlightColor',[0.6 0.7 0.8]);
    mk(p3,'text',[0.03 0.76 0.80 0.19],'3   Environmental disturbances', ...
        'FontSize',0.55,'FontWeight','bold','ForegroundColor',navy);
    bg = uibuttongroup(p3,'Units','normalized','Position',[0.03 0.36 0.94 0.36], ...
        'BackgroundColor','w','BorderType','none');
    rbOff = uicontrol(bg,'Style','radiobutton','Units','normalized','String','Off', ...
        'Position',[0.02 0.1 0.25 0.8],'BackgroundColor','w','FontUnits','normalized','FontSize',0.55);
    rbMod = uicontrol(bg,'Style','radiobutton','Units','normalized','String','Moderate', ...
        'Position',[0.36 0.1 0.28 0.8],'BackgroundColor','w','FontUnits','normalized','FontSize',0.55);
    rbSev = uicontrol(bg,'Style','radiobutton','Units','normalized','String','Severe', ...
        'Position',[0.70 0.1 0.28 0.8],'BackgroundColor','w','FontUnits','normalized','FontSize',0.55); %#ok<NASGU>
    set(bg,'SelectedObject',rbMod);
    lblDist = mk(p3,'text',[0.03 0.06 0.94 0.22],'','FontSize',0.55, ...
        'ForegroundColor',[0.3 0.3 0.3]);

    % ---------- 4. heading controller ----------
    p4 = uipanel(fig,'Units','normalized','Position',[0.02 0.20 0.46 0.13], ...
        'BackgroundColor','w','BorderType','line','HighlightColor',[0.6 0.7 0.8]);
    mk(p4,'text',[0.03 0.70 0.70 0.26],'4   Heading controller', ...
        'FontSize',0.62,'FontWeight','bold','ForegroundColor',navy);
    mk(p4,'text',[0.03 0.38 0.22 0.26],'Controller:','FontSize',0.62);
    ddCtrl = mk(p4,'popupmenu',[0.26 0.36 0.60 0.30], ...
        {'Adaptive PID (proposed)','Fixed-gain PID','PD controller','Sliding-mode controller'}, ...
        'FontSize',0.55);
    chkCmp = uicontrol(p4,'Style','checkbox','Units','normalized', ...
        'Position',[0.03 0.03 0.94 0.28],'BackgroundColor','w', ...
        'String','Compare all 4 controllers on the same mission (runs it 4 times)', ...
        'HorizontalAlignment','left','FontUnits','normalized','FontSize',0.55);

    % ---------- summary + footer ----------
    lblSum = uicontrol(fig,'Style','text','Units','normalized','Position',[0.02 0.125 0.96 0.05], ...
        'FontUnits','normalized','FontSize',0.62,'FontWeight','bold', ...
        'ForegroundColor',navy,'BackgroundColor',paper,'HorizontalAlignment','left');
    uicontrol(fig,'Style','text','Units','normalized','Position',[0.02 0.03 0.50 0.07], ...
        'String','Tip: speeds are in units/s. Closing this window starts with the defaults (Lake, 1 robot, speed 4, Moderate).', ...
        'FontUnits','normalized','FontSize',0.30,'ForegroundColor',[0.45 0.45 0.45], ...
        'BackgroundColor',paper,'HorizontalAlignment','left');
    btnReset = uicontrol(fig,'Style','pushbutton','Units','normalized', ...
        'Position',[0.56 0.03 0.12 0.075],'String','Reset', ...
        'FontUnits','normalized','FontSize',0.38);
    btnStart = uicontrol(fig,'Style','pushbutton','Units','normalized', ...
        'Position',[0.70 0.03 0.28 0.075],'String','START MISSION', ...
        'FontUnits','normalized','FontSize',0.45,'FontWeight','bold', ...
        'BackgroundColor',[0.10 0.55 0.25],'ForegroundColor','w');

    % ---------- callbacks ----------
    set(ddEnv,'Callback',@(~,~) refresh());
    set(spN,'Callback',@(~,~) refresh());
    set(bg,'SelectionChangedFcn',@(~,~) refresh());
    set(ddCtrl,'Callback',@(~,~) refresh());
    set(chkCmp,'Callback',@(~,~) refresh());
    for r = 1:5
        set(sld(r),'Callback',@(s,~) set(val(r),'String',sprintf('%.1f u/s',get(s,'Value'))));
    end
    set(btnReset,'Callback',@(~,~) reset_all());
    set(btnStart,'Callback',@(~,~) start_now());

    refresh();
    uiwait(fig);

    % ---------- read result (defaults if window was just closed) ----------
    if ishandle(fig) && isappdata(fig,'cfg')
        cfg = getappdata(fig,'cfg');
    end
    if ishandle(fig), delete(fig); end

    % ================= nested helpers =================
    function h = mk(parent,style,pos,str,varargin)
        h = uicontrol(parent,'Style',style,'Units','normalized','Position',pos, ...
            'BackgroundColor','w','HorizontalAlignment','left', ...
            'FontUnits','normalized');
        if strcmp(style,'popupmenu')
            set(h,'String',str);
        else
            set(h,'String',str);
        end
        if ~isempty(varargin), set(h,varargin{:}); end
    end

    function refresh()
        n = get(spN,'Value');
        for k = 1:5
            state = 'off';  vis = 'off';
            if k <= n, state = 'on'; vis = 'on'; end
            set(sld(k),'Enable',state);  set(val(k),'Enable',state);
            set(nm(k),'Enable',state);   set(sw(k),'Visible',vis);
        end

        env = envs{get(ddEnv,'Value')};
        [bnd,wc,bc,desc,ntr,xl,yl] = env_preview_info(env);
        cla(ax);  hold(ax,'on');
        patch('Parent',ax,'XData',[xl(1) xl(2) xl(2) xl(1)], ...
            'YData',[yl(1) yl(1) yl(2) yl(2)],'FaceColor',bc,'EdgeColor','none');
        patch('Parent',ax,'XData',bnd(:,1),'YData',bnd(:,2),'FaceColor',wc, ...
            'FaceAlpha',0.6,'EdgeColor',[0.1 0.2 0.7],'LineWidth',2);
        hold(ax,'off');
        axis(ax,'equal');  xlim(ax,xl);  ylim(ax,yl);
        set(ax,'XTick',[],'YTick',[],'Box','on');
        set(lblDesc,'String',sprintf('%s  -  %s',env,desc));
        set(lblInfo,'String',sprintf('Area %d x %d units   |   %d pieces of floating trash', ...
            diff(xl),diff(yl),ntr));

        dsel = get(get(bg,'SelectedObject'),'String');
        switch dsel
            case 'Off',      msg = 'Calm water: no wind, current or waves.';
            case 'Moderate', msg = 'Realistic wind gusts, current and waves.';
            otherwise,       msg = 'Double strength: expect heavy drift and rough water.';
        end
        set(lblDist,'String',msg);
        cnames = {'adaptive PID','fixed-gain PID','PD','sliding-mode'};
        if get(chkCmp,'Value')
            ctxt = 'comparing all 4 controllers';
        else
            ctxt = ['controller: ' cnames{get(ddCtrl,'Value')}];
        end
        set(lblSum,'String',sprintf('Mission: %d robot(s) in the %s, disturbances %s, %s', ...
            n,env,lower(dsel),ctxt));
    end

    function reset_all()
        set(ddEnv,'Value',1);  set(spN,'Value',1);
        for k = 1:5
            set(sld(k),'Value',4);  set(val(k),'String','4.0 u/s');
        end
        set(bg,'SelectedObject',rbMod);
        set(ddCtrl,'Value',1);  set(chkCmp,'Value',0);
        refresh();
    end

    function start_now()
        sp = 4*ones(1,5);
        for k = 1:5, sp(k) = get(sld(k),'Value'); end
        out.env_name    = envs{get(ddEnv,'Value')};
        out.num_robots  = get(spN,'Value');
        out.speeds      = sp;
        out.dist_choice = get(get(bg,'SelectedObject'),'String');
        out.controller  = get(ddCtrl,'Value');
        out.compare     = logical(get(chkCmp,'Value'));
        setappdata(fig,'cfg',out);
        uiresume(fig);
    end
end

function [bnd,water,bg,desc,ntrash,xl,yl] = env_preview_info(name)
% Preview geometry only (mirrors the environment table in the main script).
    switch name
        case 'Lake'
            bnd = [0 0; 120 0; 110 55; 80 72; 40 75; 10 60; 0 30];
            water = [0.4 0.72 0.95];  bg = [0.6 0.85 1.0];
            desc = 'Large irregular natural lake';  ntrash = 25;
            xl = [0 120];  yl = [0 80];
        case 'Pond'
            t = linspace(0,2*pi,16)';
            bnd = [30+25*cos(t) 30+22*sin(t)];
            water = [0.3 0.65 0.45];  bg = [0.55 0.80 0.65];
            desc = 'Small compact pond';  ntrash = 12;
            xl = [0 60];  yl = [0 60];
        case 'Pool'
            bnd = [5 5; 75 5; 75 35; 5 35];
            water = [0.1 0.65 0.85];  bg = [0.7 0.90 0.98];
            desc = 'Rectangular swimming pool';  ntrash = 15;
            xl = [0 80];  yl = [0 40];
        case 'River'
            tx = [0 30 60 90 120 150 180];  ty = [30 32 28 33 27 31 30];
            bx = [0 30 60 90 120 150 180];  by = [10 12 8 13 7 11 10];
            bnd = [[tx fliplr(bx)]' [ty fliplr(by)]'];
            water = [0.3 0.55 0.80];  bg = [0.55 0.75 0.90];
            desc = 'Long narrow river channel';  ntrash = 30;
            xl = [0 180];  yl = [0 40];
        otherwise % Ocean
            bnd = [0 0; 200 0; 200 110; 0 110];
            water = [0.05 0.35 0.75];  bg = [0.2 0.55 0.90];
            desc = 'Open ocean surface';  ntrash = 40;
            xl = [0 200];  yl = [0 120];
    end
end