classdef GUI < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        PIC16F877PIDControllerUIFigure  matlab.ui.Figure
        sLabel                          matlab.ui.control.Label
        DurationSpinner                 matlab.ui.control.Spinner
        DurationSpinnerLabel            matlab.ui.control.Label
        FeedbackEditField               matlab.ui.control.EditField
        FeedbackEditFieldLabel          matlab.ui.control.Label
        DesireEditField                 matlab.ui.control.NumericEditField
        DesireEditFieldLabel            matlab.ui.control.Label
        ConnectherefirstLabel           matlab.ui.control.Label
        Lamp                            matlab.ui.control.Lamp
        DisconnectButton                matlab.ui.control.Button
        ConnectButton                   matlab.ui.control.Button
        rpmLabel_2                      matlab.ui.control.Label
        rpmLabel                        matlab.ui.control.Label
        RS232MotorSpeedControllerLabel  matlab.ui.control.Label
        StartButton                     matlab.ui.control.Button
        SendButton                      matlab.ui.control.Button
        UIAxes                          matlab.ui.control.UIAxes
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
                writeline(app.connectPort,strcat(num2str(app.runTime),'&'));
                writeline(app.connectPort,strcat(num2str(app.DesireEditField.Value*2*pi/60),'&'));
                app.desiredSpeed=app.DesireEditField.Value;
                for i = 1:length(duration)
                    if i~=1
                        u=str2double(readline(app.connectPort));
                        if app.sendFlag==1
                            app.desiredSpeed=app.DesireEditField.Value;
                            str=strcat('#',num2str(app.desiredSpeed*(2*pi)/60));
                            writeline(app.connectPort,strcat(str,'&')); 
                            app.sendFlag=0;
                        end
                        x(:,i) = x(:,i-1) + step*xd(:,i-1);
                        xd(:,i) = A*x(:,i) + B*u;
                        y(i) = C*x(:,i)+D*u;
                    end
                    plot(app.UIAxes,duration(1:i),y(1:i)*60/(2*pi),'LineWidth',2.5,'Color','r');
                    yline(app.UIAxes,app.desiredSpeed,'-.',num2str(app.desiredSpeed));                   
                    app.FeedbackEditField.Value=num2str(round(y(i)*60/(2*pi),1)); 
                    drawnow;                      
                    if i<(app.runTime*100+1) % Stop sending signal at the last iteration
                        writeline(app.connectPort,strcat(num2str(y(i)),'&'));                   
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

            % Create PIC16F877PIDControllerUIFigure and hide until all components are created
            app.PIC16F877PIDControllerUIFigure = uifigure('Visible', 'off');
            app.PIC16F877PIDControllerUIFigure.Position = [100 100 763 348];
            app.PIC16F877PIDControllerUIFigure.Name = 'PIC16F877 PID Controller';

            % Create UIAxes
            app.UIAxes = uiaxes(app.PIC16F877PIDControllerUIFigure);
            xlabel(app.UIAxes, 'Time (s)')
            ylabel(app.UIAxes, 'Feedback (rpm)')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.FontSize = 14;
            app.UIAxes.Position = [299 9 452 279];

            % Create SendButton
            app.SendButton = uibutton(app.PIC16F877PIDControllerUIFigure, 'push');
            app.SendButton.ButtonPushedFcn = createCallbackFcn(app, @SendButtonPushed, true);
            app.SendButton.FontSize = 18;
            app.SendButton.Enable = 'off';
            app.SendButton.Visible = 'off';
            app.SendButton.Position = [110 23 89 29];
            app.SendButton.Text = 'Send';

            % Create StartButton
            app.StartButton = uibutton(app.PIC16F877PIDControllerUIFigure, 'push');
            app.StartButton.ButtonPushedFcn = createCallbackFcn(app, @StartButtonPushed, true);
            app.StartButton.FontSize = 18;
            app.StartButton.Position = [110 23 89 29];
            app.StartButton.Text = 'Start';

            % Create RS232MotorSpeedControllerLabel
            app.RS232MotorSpeedControllerLabel = uilabel(app.PIC16F877PIDControllerUIFigure);
            app.RS232MotorSpeedControllerLabel.HorizontalAlignment = 'center';
            app.RS232MotorSpeedControllerLabel.FontSize = 22;
            app.RS232MotorSpeedControllerLabel.FontWeight = 'bold';
            app.RS232MotorSpeedControllerLabel.Position = [219 309 328 27];
            app.RS232MotorSpeedControllerLabel.Text = 'RS232 Motor Speed Controller';

            % Create rpmLabel
            app.rpmLabel = uilabel(app.PIC16F877PIDControllerUIFigure);
            app.rpmLabel.FontSize = 18;
            app.rpmLabel.Position = [215 135 51 22];
            app.rpmLabel.Text = 'rpm';

            % Create rpmLabel_2
            app.rpmLabel_2 = uilabel(app.PIC16F877PIDControllerUIFigure);
            app.rpmLabel_2.FontSize = 18;
            app.rpmLabel_2.Position = [215 85 51 22];
            app.rpmLabel_2.Text = 'rpm';

            % Create ConnectButton
            app.ConnectButton = uibutton(app.PIC16F877PIDControllerUIFigure, 'push');
            app.ConnectButton.ButtonPushedFcn = createCallbackFcn(app, @ConnectButtonPushed, true);
            app.ConnectButton.FontSize = 18;
            app.ConnectButton.Position = [27 237 100 29];
            app.ConnectButton.Text = 'Connect';

            % Create DisconnectButton
            app.DisconnectButton = uibutton(app.PIC16F877PIDControllerUIFigure, 'push');
            app.DisconnectButton.ButtonPushedFcn = createCallbackFcn(app, @DisconnectButtonPushed, true);
            app.DisconnectButton.FontSize = 18;
            app.DisconnectButton.Enable = 'off';
            app.DisconnectButton.Position = [144 237 104 29];
            app.DisconnectButton.Text = 'Disconnect';

            % Create Lamp
            app.Lamp = uilamp(app.PIC16F877PIDControllerUIFigure);
            app.Lamp.Position = [260 242 20 20];

            % Create ConnectherefirstLabel
            app.ConnectherefirstLabel = uilabel(app.PIC16F877PIDControllerUIFigure);
            app.ConnectherefirstLabel.FontSize = 13;
            app.ConnectherefirstLabel.FontColor = [1 0 0];
            app.ConnectherefirstLabel.Visible = 'off';
            app.ConnectherefirstLabel.Position = [24 266 112 22];
            app.ConnectherefirstLabel.Text = 'Connect here first!';

            % Create DesireEditFieldLabel
            app.DesireEditFieldLabel = uilabel(app.PIC16F877PIDControllerUIFigure);
            app.DesireEditFieldLabel.HorizontalAlignment = 'right';
            app.DesireEditFieldLabel.FontSize = 18;
            app.DesireEditFieldLabel.Position = [72 136 58 22];
            app.DesireEditFieldLabel.Text = 'Desire';

            % Create DesireEditField
            app.DesireEditField = uieditfield(app.PIC16F877PIDControllerUIFigure, 'numeric');
            app.DesireEditField.ValueDisplayFormat = '%.0f';
            app.DesireEditField.HorizontalAlignment = 'left';
            app.DesireEditField.FontSize = 18;
            app.DesireEditField.Position = [138 133 71 25];

            % Create FeedbackEditFieldLabel
            app.FeedbackEditFieldLabel = uilabel(app.PIC16F877PIDControllerUIFigure);
            app.FeedbackEditFieldLabel.HorizontalAlignment = 'right';
            app.FeedbackEditFieldLabel.FontSize = 18;
            app.FeedbackEditFieldLabel.Position = [45 86 84 22];
            app.FeedbackEditFieldLabel.Text = 'Feedback';

            % Create FeedbackEditField
            app.FeedbackEditField = uieditfield(app.PIC16F877PIDControllerUIFigure, 'text');
            app.FeedbackEditField.Editable = 'off';
            app.FeedbackEditField.FontSize = 18;
            app.FeedbackEditField.Position = [138 83 71 26];

            % Create DurationSpinnerLabel
            app.DurationSpinnerLabel = uilabel(app.PIC16F877PIDControllerUIFigure);
            app.DurationSpinnerLabel.HorizontalAlignment = 'right';
            app.DurationSpinnerLabel.FontSize = 18;
            app.DurationSpinnerLabel.Position = [56 185 74 22];
            app.DurationSpinnerLabel.Text = 'Duration';

            % Create DurationSpinner
            app.DurationSpinner = uispinner(app.PIC16F877PIDControllerUIFigure);
            app.DurationSpinner.Limits = [1 Inf];
            app.DurationSpinner.ValueDisplayFormat = '%.0f';
            app.DurationSpinner.HorizontalAlignment = 'left';
            app.DurationSpinner.FontSize = 18;
            app.DurationSpinner.Position = [138 183 72 24];
            app.DurationSpinner.Value = 4;

            % Create sLabel
            app.sLabel = uilabel(app.PIC16F877PIDControllerUIFigure);
            app.sLabel.FontSize = 18;
            app.sLabel.Position = [215 185 51 22];
            app.sLabel.Text = 's';

            % Show the figure after all components are created
            app.PIC16F877PIDControllerUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = GUI

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.PIC16F877PIDControllerUIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.PIC16F877PIDControllerUIFigure)
        end
    end
end
