%% ---------------- USER INPUT: ENVIRONMENT SELECTION ----------------

env_options = {'Lake', 'Pond', 'Pool', 'River', 'Ocean'};

[env_choice, env_ok] = listdlg( ...
    'PromptString', 'Select the water environment:', ...
    'SelectionMode', 'single', ...
    'ListString', env_options, ...
    'ListSize', [220 130], ...
    'Name', 'Environment Selection', ...
    'OKString', 'Select', ...
    'InitialValue', 1);

if ~env_ok
    disp('No environment selected. Defaulting to Lake.');
    env_choice = 1;
end

env_name = env_options{env_choice};
fprintf('Environment selected: %s\n', env_name);

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
        obstacle_speed_scale = 0.82;

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

%% ---------------- USER INPUT: NUMBER OF ROBOTS ----------------

num_robots_input = inputdlg('Enter number of robots to deploy (1-5):', ...
    'Robot Deployment', 1, {'1'});

if isempty(num_robots_input)
    disp('No input provided. Using 1 robot.');
    num_robots_total = 1;
else
    num_robots_total = round(str2double(num_robots_input{1}));
    num_robots_total = max(1, min(5, num_robots_total));
end

fprintf('Deploying %d robot(s)...\n', num_robots_total);

%% ---------------- USER INPUT: ROBOT SPEEDS ----------------

speed_prompts  = arrayfun(@(r) sprintf('Speed for Robot %d (1-10):', r), ...
    1:num_robots_total, 'UniformOutput', false);
speed_defaults = repmat({'4'}, 1, num_robots_total);

speed_input = inputdlg(speed_prompts, 'Robot Speeds', 1, speed_defaults);

robot_speeds = zeros(1, num_robots_total);
if isempty(speed_input)
    disp('No speed input provided. Using default speed 4 for all robots.');
    robot_speeds(:) = 4;
else
    for r = 1:num_robots_total
        v = str2double(speed_input{r});
        if isnan(v), v = 4; fprintf('Invalid speed for Robot %d. Using default: 4\n', r); end
        robot_speeds(r) = max(1, min(10, v));
    end
end

fprintf('\nRobot speeds assigned:\n');
for r = 1:num_robots_total
    fprintf('  Robot %d: %.1f units/s\n', r, robot_speeds(r));
end

%% ---------------- ROBOT COLORS ----------------

robot_colors = [
    1.0  0.0  0.0;
    0.0  0.7  0.0;
    0.0  0.0  1.0;
    1.0  0.5  0.0;
    0.6  0.0  0.8;
];

%% ---------------- FIGURE & ENVIRONMENT DRAWING ----------------

figure('Color','white');
hold on;
axis equal;
xlim(xlim_range);
ylim(ylim_range);

rectangle('Position',[xlim_range(1) ylim_range(1) ...
    diff(xlim_range) diff(ylim_range)], ...
    'FaceColor', bg_color, 'EdgeColor','none');

title(sprintf('Autonomous Water Surface Cleaning (%d robot(s)) — %s', ...
    num_robots_total, env_name));
xlabel('X Position');
ylabel('Y Position');

fill(boundary(:,1), boundary(:,2), water_color, 'FaceAlpha', 0.45);
plot(boundary(:,1), boundary(:,2), 'b', 'LineWidth', 2);

annotation_x = xlim_range(1) + 0.55*diff(xlim_range);
annotation_y = ylim_range(2) - 0.07*diff(ylim_range);
text(annotation_x, annotation_y, ...
    sprintf('[%s] %s', env_name, env_desc), ...
    'FontSize', 9, 'Color', [0.1 0.1 0.5], ...
    'BackgroundColor', [0.95 0.95 1], 'EdgeColor', [0.6 0.6 0.8]);

plot(home_base(1), home_base(2), 'kp', 'MarkerSize',12, 'MarkerFaceColor','y');
text(home_base(1)+1.5, home_base(2)+1.5, 'Home', 'FontSize', 9);

%% ---------------- GLOBAL COVERAGE PATH ----------------

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

for i = 1:2:size(all_waypoints,1)-1
    plot(all_waypoints(i:i+1,1), all_waypoints(i:i+1,2), 'm--', 'LineWidth', 1.5);
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

%% ---------------- INITIALISE ROBOTS ----------------

total_wp     = size(all_waypoints, 1);
wp_per_robot = ceil(total_wp / num_robots_total);

detection_radius = 0.05 * W;
arrow_length     = 0.04 * W;

robots = struct();
for r = 1:num_robots_total
    if strcmp(env_name, 'River')
        start_x = home_base(1) + (r-1) * 12;
        start_y = (ymin + ymax) / 2 + (mod(r,2)*2-1) * 2;
    else
        start_x = home_base(1) + (r-1) * max(spacing, 6);
        start_y = home_base(2) + mod(r-1,2) * 3;
    end

    robots(r).x        = start_x;
    robots(r).y        = start_y;
    robots(r).theta    = 0;
    robots(r).v        = robot_speeds(r);
    robots(r).done     = false;
    robots(r).returning = false;
    robots(r).stuck_counter = 0;

    wp_start = (r-1)*wp_per_robot + 1;
    wp_end   = min(r*wp_per_robot, total_wp);
    robots(r).waypoints   = all_waypoints(wp_start:wp_end, :);
    robots(r).current_wp  = 1;
    robots(r).prev_pos    = [start_x, start_y];

    rcolor = robot_colors(r,:);
    robots(r).body  = plot(robots(r).x, robots(r).y, 'o', ...
        'MarkerSize',14,'MarkerFaceColor',rcolor,'MarkerEdgeColor','k');
    robots(r).dir   = quiver(robots(r).x, robots(r).y, ...
        arrow_length*cos(robots(r).theta), arrow_length*sin(robots(r).theta), ...
        0,'k','LineWidth',2);
    robots(r).label = text(robots(r).x+1, robots(r).y+1.5, ...
        sprintf('R%d (v=%.1f)',r,robot_speeds(r)), ...
        'FontSize',8,'Color',rcolor,'FontWeight','bold');
end

%% ---- INTER-ROBOT AVOIDANCE PARAMETERS ----
robot_repulsion_radius   = 0.035 * W;
robot_repulsion_strength = 2.0;
boundary_margin          = 1.5;

%% ---------------- PERFORMANCE METRICS ----------------

total_distance  = zeros(1, num_robots_total);
sim_time        = 0;
time_log        = [];
trash_log       = [];
dist_log        = zeros(0, num_robots_total);
collection_time = [];
collection_type = [];

stats_text = text(xlim_range(1)+1, ylim_range(2)-3, '', ...
    'FontSize',9,'BackgroundColor','w','EdgeColor','k');

%% ---------------- LEGEND ----------------

legend_handles = gobjects(num_robots_total,1);
for r = 1:num_robots_total
    legend_handles(r) = plot(nan,nan,'o', ...
        'MarkerFaceColor',robot_colors(r,:),'MarkerEdgeColor','k', ...
        'MarkerSize',10,'DisplayName',sprintf('Robot %d (v=%.1f)',r,robot_speeds(r)));
end
legend(legend_handles,'Location','southeast');

%% ---------------- MAIN LOOP ----------------

dt   = 0.1;
all_done = false;

while ~all_done

    %% ---- MOVE FLOATING OBSTACLES ----
    for k = 1:num_obstacles
        if ~obstacle_float_flags(k), continue; end  % skip fixed obstacles

        obs = obstacles(k,:);
        new_cx = obs(1) + obs_velocity(k,1)*dt;
        new_cy = obs(2) + obs_velocity(k,2)*dt;

        % Compute safe clearance radius for this obstacle
        if obs(3)==1,      obs_r = obs(4);
        elseif obs(3)==2,  obs_r = max(obs(4), obs(5));
        else,              obs_r = obs(4);
        end
        clearance = obs_r + 1.0;

        check_a  = linspace(0, 2*pi, 9); check_a(end) = [];
        check_px = new_cx + clearance * cos(check_a);
        check_py = new_cy + clearance * sin(check_a);
        all_inside = all(inpolygon(check_px, check_py, boundary(:,1), boundary(:,2)));

        if all_inside
            collision = false;
            for j = 1:num_obstacles
                if j==k, continue; end
                obs_j = obstacles(j,:);
                if obs_j(3)==1,      r_j = obs_j(4);
                elseif obs_j(3)==2,  r_j = max(obs_j(4),obs_j(5));
                else,                r_j = obs_j(4);
                end
                if norm([new_cx new_cy] - obs_j(1:2)) < (obs_r + r_j + 1.5)
                    collision = true; break;
                end
            end
            if ~collision
                obstacles(k,1) = new_cx;
                obstacles(k,2) = new_cy;
            else
                obs_velocity(k,:) = -obs_velocity(k,:);
            end
        else
            check_px2 = obs(1) - obs_velocity(k,1)*dt + clearance*cos(check_a);
            check_py2 = obs(2) + obs_velocity(k,2)*dt + clearance*sin(check_a);
            if all(inpolygon(check_px2, check_py2, boundary(:,1), boundary(:,2)))
                obs_velocity(k,1) = -obs_velocity(k,1);
                obstacles(k,1) = obs(1) + obs_velocity(k,1)*dt;
                obstacles(k,2) = obs(2) + obs_velocity(k,2)*dt;
            else
                check_px3 = obs(1) + obs_velocity(k,1)*dt + clearance*cos(check_a);
                check_py3 = obs(2) - obs_velocity(k,2)*dt + clearance*sin(check_a);
                if all(inpolygon(check_px3, check_py3, boundary(:,1), boundary(:,2)))
                    obs_velocity(k,2) = -obs_velocity(k,2);
                    obstacles(k,1) = obs(1) + obs_velocity(k,1)*dt;
                    obstacles(k,2) = obs(2) + obs_velocity(k,2)*dt;
                else
                    obs_velocity(k,:) = -obs_velocity(k,:);
                end
            end
        end

        % Redraw this floating obstacle at its new position
        cx_new = obstacles(k,1); cy_new = obstacles(k,2);
        switch obs(3)
            case 1
                theta_draw = linspace(0,2*pi,50);
                set(obs_handles{k}, ...
                    'XData', cx_new + obs(4)*cos(theta_draw), ...
                    'YData', cy_new + obs(4)*sin(theta_draw));
            case 2
                s4=obs(4); s5=max(obs(5),obs(4)*0.6);
                set(obs_handles{k}, ...
                    'XData', [cx_new-s4 cx_new+s4 cx_new+s4 cx_new-s4], ...
                    'YData', [cy_new-s5 cy_new-s5 cy_new+s5 cy_new+s5]);
            case 3
                set(obs_handles{k}, ...
                    'XData', [cx_new cx_new+obs(4) cx_new-obs(4)], ...
                    'YData', [cy_new+obs(4) cy_new-obs(4)/2 cy_new-obs(4)/2]);
        end
    end

    %% ---- MOVE TRASH ----
    for i = 1:num_trash
        if collected(i)==0
            new_pos = trash(i,:) + trash_velocity(i,:)*dt;
            if inpolygon(new_pos(1),new_pos(2),boundary(:,1),boundary(:,2))
                valid = true;
                for k = 1:num_obstacles
                    obs = obstacles(k,:);
                    d = norm(new_pos - obs(1:2));
                    if obs(3)==1, sm=obs(4)+2.5;
                    elseif obs(3)==2, sm=max(obs(4),obs(5))+2.5;
                    else, sm=obs(4)+2.5; end
                    if d < sm, valid=false; break; end
                end
                if valid
                    trash(i,:) = new_pos;
                else
                    trash_velocity(i,:) = -trash_velocity(i,:);
                end
            else
                if strcmp(env_name, 'River') && new_pos(1) > xmax
                    trash(i,1) = xmin + 2;
                    trash(i,2) = ymin + (ymax-ymin)*rand();
                    if ~inpolygon(trash(i,1), trash(i,2), boundary(:,1), boundary(:,2))
                        trash(i,2) = (ymin+ymax)/2;
                    end
                else
                    trash_velocity(i,2) = -trash_velocity(i,2);
                    if new_pos(1) < xmin
                        trash_velocity(i,1) = abs(trash_velocity(i,1));
                    end
                end
            end
            set(trash_plot(i),'XData',trash(i,1),'YData',trash(i,2));
        end
    end

    %% ---- UPDATE EACH ROBOT ----
    for r = 1:num_robots_total
        if robots(r).done, continue; end

        rx = robots(r).x; ry = robots(r).y;

        % STUCK DETECTION
        dist_moved = norm([rx ry] - robots(r).prev_pos);
        if dist_moved < 0.05 * robots(r).v * dt
            robots(r).stuck_counter = robots(r).stuck_counter + 1;
        else
            robots(r).stuck_counter = 0;
        end
        robots(r).prev_pos = [rx ry];

        if robots(r).stuck_counter > 20
            robots(r).theta = robots(r).theta + pi/3 + 0.5*randn();
            robots(r).stuck_counter = 0;
        end

        if robots(r).returning
            if norm([rx ry]-home_base) < 2
                robots(r).done = true;
                continue;
            end
            target = home_base;

        else
            trash_found = false;
            for i = 1:num_trash
                if collected(i)==0 && norm([rx ry]-trash(i,:)) < detection_radius
                    trash_found = true; trash_index = i; break;
                end
            end

            if trash_found
                target = trash(trash_index,:);
                if norm([rx ry]-target) <= 2
                    collected(trash_index) = 1;
                    trash(trash_index,:) = [NaN NaN];
                    set(trash_plot(trash_index),'Visible','off');
                    collection_time(end+1) = sim_time;
                    collection_type(end+1) = trash_color_idx(trash_index);
                    continue;
                end
            else
                if robots(r).current_wp <= size(robots(r).waypoints,1)
                    target = robots(r).waypoints(robots(r).current_wp,:);
                    if norm([rx ry]-target) < 2
                        robots(r).current_wp = robots(r).current_wp + 1;
                        continue;
                    end
                else
                    remaining = find(collected==0);
                    if isempty(remaining)
                        robots(r).returning = true;
                        continue;
                    end
                    dists = vecnorm(trash(remaining,:)-[rx ry],2,2);
                    [~,ii] = min(dists);
                    target = trash(remaining(ii),:);
                end
            end
        end

        % ---- MOVE TOWARD TARGET ----
        angle_to_target = atan2(target(2)-ry, target(1)-rx);
        angle_error = atan2(sin(angle_to_target-robots(r).theta), ...
                            cos(angle_to_target-robots(r).theta));
        omega = 2 * angle_error;

        % INTER-ROBOT REPULSION
        repulsion_dx = 0; repulsion_dy = 0;
        for rr = 1:num_robots_total
            if rr == r || robots(rr).done, continue; end
            diff_vec = [rx ry] - [robots(rr).x robots(rr).y];
            dist_rr  = norm(diff_vec);
            if dist_rr < robot_repulsion_radius && dist_rr > 1e-3
                repulsion_force = robot_repulsion_strength * ...
                    (robot_repulsion_radius - dist_rr) / robot_repulsion_radius;
                repulsion_dx = repulsion_dx + repulsion_force * diff_vec(1)/dist_rr;
                repulsion_dy = repulsion_dy + repulsion_force * diff_vec(2)/dist_rr;
            end
        end

        desired_dx = cos(robots(r).theta) + repulsion_dx;
        desired_dy = sin(robots(r).theta) + repulsion_dy;
        blended_angle = atan2(desired_dy, desired_dx);
        blend_error = atan2(sin(blended_angle - robots(r).theta), ...
                            cos(blended_angle - robots(r).theta));
        omega = omega + 3.0 * blend_error;

        % ---- OBSTACLE AVOIDANCE ----
        next_x = rx + robots(r).v*cos(robots(r).theta)*dt;
        next_y = ry + robots(r).v*sin(robots(r).theta)*dt;

        avoid = false;
        for k = 1:num_obstacles
            obs = obstacles(k,:);
            d = norm([next_x next_y]-obs(1:2));
            if obs(3)==1, sd=obs(4)+2;
            elseif obs(3)==2, sd=max(obs(4),obs(5))+2;
            else, sd=obs(4)+2; end
            if d < sd
                avoid = true;
                angle_away = atan2(ry-obs(2), rx-obs(1));
                robots(r).theta = angle_away + pi/2;
                break;
            end
        end

        if avoid
            robots(r).x = rx + robots(r).v*cos(robots(r).theta)*dt;
            robots(r).y = ry + robots(r).v*sin(robots(r).theta)*dt;
        else
            robots(r).theta = robots(r).theta + omega*dt;
            nx = rx + robots(r).v*cos(robots(r).theta)*dt;
            ny = ry + robots(r).v*sin(robots(r).theta)*dt;

            if inpolygon(nx, ny, boundary(:,1), boundary(:,2))
                robots(r).x = nx;
                robots(r).y = ny;
            else
                ny_flip = ry - robots(r).v*sin(robots(r).theta)*dt;
                nx_flip = rx + robots(r).v*cos(robots(r).theta)*dt;
                if inpolygon(nx_flip, ny_flip, boundary(:,1), boundary(:,2))
                    robots(r).x = nx_flip;
                    robots(r).y = ny_flip;
                    robots(r).theta = -robots(r).theta;
                else
                    ny_flip2 = ry + robots(r).v*sin(robots(r).theta)*dt;
                    nx_flip2 = rx - robots(r).v*cos(robots(r).theta)*dt;
                    if inpolygon(nx_flip2, ny_flip2, boundary(:,1), boundary(:,2))
                        robots(r).x = nx_flip2;
                        robots(r).y = ny_flip2;
                        robots(r).theta = pi - robots(r).theta;
                    else
                        cx_b = mean(boundary(:,1));
                        cy_b = mean(boundary(:,2));
                        robots(r).theta = atan2(cy_b - ry, cx_b - rx) + 0.3*randn();
                    end
                end
            end

            check_angles = linspace(0, 2*pi, 8);
            check_pts_x  = robots(r).x + boundary_margin * cos(check_angles);
            check_pts_y  = robots(r).y + boundary_margin * sin(check_angles);
            inside_check = inpolygon(check_pts_x, check_pts_y, ...
                                     boundary(:,1), boundary(:,2));
            if sum(inside_check) < 5
                cx_b = mean(boundary(:,1));
                cy_b = mean(boundary(:,2));
                inward_angle = atan2(cy_b - robots(r).y, cx_b - robots(r).x);
                inward_error = atan2(sin(inward_angle - robots(r).theta), ...
                                     cos(inward_angle - robots(r).theta));
                robots(r).theta = robots(r).theta + 0.5 * inward_error;
            end
        end

        total_distance(r) = total_distance(r) + robots(r).v*dt;
    end

    sim_time = sim_time + dt;

    % ---- LOGGING ----
    time_log(end+1)  = sim_time;
    trash_log(end+1) = sum(collected);
    dist_log(end+1,:) = total_distance;

    % ---- UPDATE ROBOT GRAPHICS ----
    for r = 1:num_robots_total
        set(robots(r).body,'XData',robots(r).x,'YData',robots(r).y);
        set(robots(r).dir,'XData',robots(r).x,'YData',robots(r).y, ...
            'UData',arrow_length*cos(robots(r).theta), ...
            'VData',arrow_length*sin(robots(r).theta));
        set(robots(r).label,'Position',[robots(r).x+1, robots(r).y+1.5]);
    end

    % ---- STATS ----
    stats_str = sprintf('Env: %s\nTrash: %d/%d\nTime: %.1fs', ...
        env_name, sum(collected), num_trash, sim_time);
    for r = 1:num_robots_total
        stats_str = sprintf('%s\nR%d dist: %.1f', stats_str, r, total_distance(r));
    end
    set(stats_text,'String',stats_str);

    drawnow;

    all_done = all([robots.done]);
    if sum(collected)==num_trash && ~all_done
        for r = 1:num_robots_total
            robots(r).returning = true;
        end
    end
end

disp('Mission Completed. All robots returned home.');

%% ---------------- FINAL STATS ----------------

fprintf('\n========================================\n');
fprintf('    MISSION COMPLETE - FINAL STATS     \n');
fprintf('========================================\n');
fprintf('Environment:                %s\n', env_name);
fprintf('Robots deployed:            %d\n', num_robots_total);
fprintf('Total trash collected:      %d/%d\n', sum(collected), num_trash);
fprintf('Collection efficiency:      %.1f%%\n', (sum(collected)/num_trash)*100);
fprintf('Total mission time:         %.2f seconds\n', sim_time);
fprintf('Total obstacles:            %d (%d fixed, %d floating)\n', ...
    num_obstacles, sum(~obstacle_float_flags), sum(obstacle_float_flags~=0));
fprintf('\nPer-robot distances and speeds:\n');
for r = 1:num_robots_total
    fprintf('  Robot %d (speed=%.1f): %.2f units\n', r, robot_speeds(r), total_distance(r));
end
fprintf('Total distance (all):       %.2f units\n', sum(total_distance));

type_names = {'Plastic','Paper','Metal','Glass','Organic','Electronic'};
if ~isempty(collection_type)
    fprintf('\nTrash type breakdown:\n');
    for t = 1:6
        count = sum(collection_type==t);
        if count>0
            fprintf('  %s: %d (%.1f%%)\n', type_names{t}, count, (count/length(collection_type))*100);
        end
    end
end
fprintf('========================================\n');

%% ---------------- PERFORMANCE GRAPHS ----------------

figure('Position',[100 100 1000 700]);

subplot(2,2,1)
plot(time_log, dist_log, 'LineWidth',2);
xlabel('Time (s)'); ylabel('Distance Traveled');
title(sprintf('[%s] Distance vs Time per Robot', env_name));
legend(arrayfun(@(r) sprintf('Robot %d (v=%.1f)',r,robot_speeds(r)), ...
    1:num_robots_total,'UniformOutput',false));
grid on;

subplot(2,2,2)
plot(time_log, trash_log,'LineWidth',2,'Color','[0 0.5 0]');
xlabel('Time (s)'); ylabel('Trash Collected');
title(sprintf('[%s] Total Trash Collection Progress', env_name));
grid on;

subplot(2,2,3)
if ~isempty(collection_time)
    stairs(collection_time, 1:length(collection_time),'LineWidth',2,'Color','r');
    xlabel('Time (s)'); ylabel('Cumulative Trash');
    title('Collection Events Over Time');
    grid on;
end

subplot(2,2,4)
if ~isempty(collection_type)
    histogram(collection_type, 1:7,'FaceColor',[0.5 0.5 0.8]);
    xlabel('Trash Type'); ylabel('Count');
    title('Trash Type Distribution');
    set(gca,'XTickLabel',{'Plastic','Paper','Metal','Glass','Organic','Electronic'});
    xtickangle(45); grid on;
end