classdef GUI < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        RS232PIDControllerUIFigure  matlab.ui.Figure
        VoltageEditField            matlab.ui.control.EditField
        VoltageEditFieldLabel       matlab.ui.control.Label
        vLabel                      matlab.ui.control.Label
        sLabel                      matlab.ui.control.Label
        DurationSpinner             matlab.ui.control.Spinner
        DurationSpinnerLabel        matlab.ui.control.Label
        FeedbackEditField           matlab.ui.control.EditField
        FeedbackEditFieldLabel      matlab.ui.control.Label
        DesiredspeedEditField       matlab.ui.control.NumericEditField
        DesiredspeedEditFieldLabel  matlab.ui.control.Label
        ConnectherefirstLabel       matlab.ui.control.Label
        Lamp                        matlab.ui.control.Lamp
        DisconnectButton            matlab.ui.control.Button
        ConnectButton               matlab.ui.control.Button
        rpmLabel_2                  matlab.ui.control.Label
        rpmLabel                    matlab.ui.control.Label
        PIC16F877PIDMotorSpeedControllerLabel  matlab.ui.control.Label
        StartButton                 matlab.ui.control.Button
        SendButton                  matlab.ui.control.Button
        UIAxes                      matlab.ui.control.UIAxes
    end

    properties (Access = public)
        connectPort=[]; % COM Port
        connectFlag=0;  % Connect state
        simrunFlag=0;   % Simulation state
        runTime=0;      % Simulation duration
        sendFlag=0;     % Changing value flag
        desiredSpeed=0; % Desired speed value
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: StartButton
        function StartButtonPushed(app, event)
            if app.connectFlag==0
                app.ConnectherefirstLabel.Visible='on';
            end
            if app.connectFlag==1
                legend(app.UIAxes, 'off'); % Turn off any existing legend
                app.StartButton.Visible='off';
                app.StartButton.Enable='off';
                app.SendButton.Visible='on';
                app.SendButton.Enable='on';
                app.simrunFlag=1; % Simulation begins
                % Initial conditions
                app.runTime=app.DurationSpinner.Value;                
                step = 0.01;  
                duration = 0:step:app.runTime;
                J = 0.01;
                b = 0.1;
                K = 0.01;
                R = 1;
                L = 0.5;
                u = 0;
                % State-space representation
                A = [-b/J, K/J; -K/L,-R/L]; 
                B = [0; 1/L];
                C = [1, 0];
                D = 0;                        
                x = zeros(2, length(duration));
                xd = zeros(2, length(duration));
                y = zeros(size(duration));
                % Select CR as terminator               
                configureTerminator(app.connectPort,"CR");
                writeline(app.connectPort,num2str(app.runTime));
                writeline(app.connectPort,num2str(app.DesiredspeedEditField.Value*2*pi/60));
                app.desiredSpeed=app.DesiredspeedEditField.Value;
                for i = 1:length(duration)
                    if i~=1
                        u=str2double(readline(app.connectPort));
                        app.VoltageEditField.Value=num2str(round(u,2));
                        if app.sendFlag==1
                            app.desiredSpeed=app.DesiredspeedEditField.Value;
                            str=strcat('#',num2str(app.desiredSpeed*(2*pi)/60));
                            writeline(app.connectPort,str); 
                            app.sendFlag=0;
                        end
                        x(:,i) = x(:,i-1) + step*xd(:,i-1);
                        xd(:,i) = A*x(:,i) + B*u;
                        y(i) = C*x(:,i)+D*u;
                    end
                    plot(app.UIAxes,duration(1:i),y(1:i)*60/(2*pi),'LineWidth',2,'Color','r');
                    yline(app.UIAxes,app.desiredSpeed,'-.',num2str(app.desiredSpeed));                                
                    app.FeedbackEditField.Value=num2str(round(y(i)*60/(2*pi),2));                
                    drawnow;                      
                    if i<(app.runTime*100+1) % Stop sending signal at the last iteration
                        writeline(app.connectPort,num2str(y(i)));                   
                    end            
                end
                app.simrunFlag=0; % Simulation ends
                app.StartButton.Enable='on';  
                app.SendButton.Enable='off';
                app.StartButton.Visible='on';  
                app.SendButton.Visible='off';
            end
        end

        % Button pushed function: ConnectButton
        function ConnectButtonPushed(app, event)
            app.connectPort=serialport("COM1",9600);
            app.connectFlag=1;
            app.ConnectButton.Enable='off';
            app.DisconnectButton.Enable='on';
            app.Lamp.Color=[1,0,0];
            app.ConnectherefirstLabel.Visible='off';
        end

        % Button pushed function: DisconnectButton
        function DisconnectButtonPushed(app, event)
            if app.simrunFlag==0 
                app.connectPort=[];
                app.connectFlag=0;
                app.ConnectButton.Enable='on';
                app.DisconnectButton.Enable='off';
                app.Lamp.Color=[0,1,0];
            end 
        end

        % Button pushed function: SendButton
        function SendButtonPushed(app, event)
            app.sendFlag=1;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create RS232PIDControllerUIFigure and hide until all components are created
            app.RS232PIDControllerUIFigure = uifigure('Visible', 'off');
            app.RS232PIDControllerUIFigure.Position = [100 100 763 352];
            app.RS232PIDControllerUIFigure.Name = 'RS232 PID Controller';

            % Create UIAxes
            app.UIAxes = uiaxes(app.RS232PIDControllerUIFigure);
            title(app.UIAxes, 'Motor speed vs Time')
            xlabel(app.UIAxes, 'Time (s)')
            ylabel(app.UIAxes, 'Feedback (rpm)')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.FontSize = 14;
            app.UIAxes.Position = [293 7 458 288];

            % Create SendButton
            app.SendButton = uibutton(app.RS232PIDControllerUIFigure, 'push');
            app.SendButton.ButtonPushedFcn = createCallbackFcn(app, @SendButtonPushed, true);
            app.SendButton.FontSize = 18;
            app.SendButton.Enable = 'off';
            app.SendButton.Visible = 'off';
            app.SendButton.Position = [110 14 81 29];
            app.SendButton.Text = 'Send';

            % Create StartButton
            app.StartButton = uibutton(app.RS232PIDControllerUIFigure, 'push');
            app.StartButton.ButtonPushedFcn = createCallbackFcn(app, @StartButtonPushed, true);
            app.StartButton.FontSize = 18;
            app.StartButton.Position = [110 14 81 29];
            app.StartButton.Text = 'Start';

            % Create PIC16F877PIDMotorSpeedControllerLabel
            app.PIC16F877PIDMotorSpeedControllerLabel = uilabel(app.RS232PIDControllerUIFigure);
            app.PIC16F877PIDMotorSpeedControllerLabel.HorizontalAlignment = 'center';
            app.PIC16F877PIDMotorSpeedControllerLabel.FontSize = 22;
            app.PIC16F877PIDMotorSpeedControllerLabel.FontWeight = 'bold';
            app.PIC16F877PIDMotorSpeedControllerLabel.Position = [171 313 423 27];
            app.PIC16F877PIDMotorSpeedControllerLabel.Text = 'PIC16F877 PID Motor Speed Controller ';

            % Create rpmLabel
            app.rpmLabel = uilabel(app.RS232PIDControllerUIFigure);
            app.rpmLabel.FontSize = 18;
            app.rpmLabel.Position = [229 155 51 22];
            app.rpmLabel.Text = 'rpm';

            % Create rpmLabel_2
            app.rpmLabel_2 = uilabel(app.RS232PIDControllerUIFigure);
            app.rpmLabel_2.FontSize = 18;
            app.rpmLabel_2.Position = [229 110 51 22];
            app.rpmLabel_2.Text = 'rpm';

            % Create ConnectButton
            app.ConnectButton = uibutton(app.RS232PIDControllerUIFigure, 'push');
            app.ConnectButton.ButtonPushedFcn = createCallbackFcn(app, @ConnectButtonPushed, true);
            app.ConnectButton.FontSize = 18;
            app.ConnectButton.Position = [27 243 100 29];
            app.ConnectButton.Text = 'Connect';

            % Create DisconnectButton
            app.DisconnectButton = uibutton(app.RS232PIDControllerUIFigure, 'push');
            app.DisconnectButton.ButtonPushedFcn = createCallbackFcn(app, @DisconnectButtonPushed, true);
            app.DisconnectButton.FontSize = 18;
            app.DisconnectButton.Enable = 'off';
            app.DisconnectButton.Position = [144 243 104 29];
            app.DisconnectButton.Text = 'Disconnect';

            % Create Lamp
            app.Lamp = uilamp(app.RS232PIDControllerUIFigure);
            app.Lamp.Position = [260 248 20 20];

            % Create ConnectherefirstLabel
            app.ConnectherefirstLabel = uilabel(app.RS232PIDControllerUIFigure);
            app.ConnectherefirstLabel.FontSize = 13;
            app.ConnectherefirstLabel.FontColor = [1 0 0];
            app.ConnectherefirstLabel.Visible = 'off';
            app.ConnectherefirstLabel.Position = [24 272 112 22];
            app.ConnectherefirstLabel.Text = 'Connect here first!';

            % Create DesiredspeedEditFieldLabel
            app.DesiredspeedEditFieldLabel = uilabel(app.RS232PIDControllerUIFigure);
            app.DesiredspeedEditFieldLabel.HorizontalAlignment = 'right';
            app.DesiredspeedEditFieldLabel.FontSize = 18;
            app.DesiredspeedEditFieldLabel.Position = [22 155 122 22];
            app.DesiredspeedEditFieldLabel.Text = 'Desired speed';

            % Create DesiredspeedEditField
            app.DesiredspeedEditField = uieditfield(app.RS232PIDControllerUIFigure, 'numeric');
            app.DesiredspeedEditField.ValueDisplayFormat = '%.0f';
            app.DesiredspeedEditField.HorizontalAlignment = 'left';
            app.DesiredspeedEditField.FontSize = 18;
            app.DesiredspeedEditField.Position = [152 153 71 25];

            % Create FeedbackEditFieldLabel
            app.FeedbackEditFieldLabel = uilabel(app.RS232PIDControllerUIFigure);
            app.FeedbackEditFieldLabel.HorizontalAlignment = 'right';
            app.FeedbackEditFieldLabel.FontSize = 18;
            app.FeedbackEditFieldLabel.Position = [58 111 84 22];
            app.FeedbackEditFieldLabel.Text = 'Feedback';

            % Create FeedbackEditField
            app.FeedbackEditField = uieditfield(app.RS232PIDControllerUIFigure, 'text');
            app.FeedbackEditField.Editable = 'off';
            app.FeedbackEditField.FontSize = 18;
            app.FeedbackEditField.Position = [152 108 71 26];

            % Create DurationSpinnerLabel
            app.DurationSpinnerLabel = uilabel(app.RS232PIDControllerUIFigure);
            app.DurationSpinnerLabel.HorizontalAlignment = 'right';
            app.DurationSpinnerLabel.FontSize = 18;
            app.DurationSpinnerLabel.Position = [70 199 74 22];
            app.DurationSpinnerLabel.Text = 'Duration';

            % Create DurationSpinner
            app.DurationSpinner = uispinner(app.RS232PIDControllerUIFigure);
            app.DurationSpinner.Limits = [1 Inf];
            app.DurationSpinner.ValueDisplayFormat = '%.0f';
            app.DurationSpinner.HorizontalAlignment = 'left';
            app.DurationSpinner.FontSize = 18;
            app.DurationSpinner.Position = [152 198 72 24];
            app.DurationSpinner.Value = 10;

            % Create sLabel
            app.sLabel = uilabel(app.RS232PIDControllerUIFigure);
            app.sLabel.FontSize = 18;
            app.sLabel.Position = [229 199 51 22];
            app.sLabel.Text = 's';

            % Create vLabel
            app.vLabel = uilabel(app.RS232PIDControllerUIFigure);
            app.vLabel.FontSize = 18;
            app.vLabel.Position = [230 65 51 22];
            app.vLabel.Text = 'v';

            % Create VoltageEditFieldLabel
            app.VoltageEditFieldLabel = uilabel(app.RS232PIDControllerUIFigure);
            app.VoltageEditFieldLabel.HorizontalAlignment = 'right';
            app.VoltageEditFieldLabel.FontSize = 18;
            app.VoltageEditFieldLabel.Position = [76 65 66 22];
            app.VoltageEditFieldLabel.Text = 'Voltage';

            % Create VoltageEditField
            app.VoltageEditField = uieditfield(app.RS232PIDControllerUIFigure, 'text');
            app.VoltageEditField.Editable = 'off';
            app.VoltageEditField.FontSize = 18;
            app.VoltageEditField.Position = [152 62 71 26];

            % Show the figure after all components are created
            app.RS232PIDControllerUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = GUI

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.RS232PIDControllerUIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.RS232PIDControllerUIFigure)
        end
    end
end