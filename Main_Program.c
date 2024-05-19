#include <16F877A.h>
#device ADC=10
#FUSES NOWDT                    //No Watch Dog Timer
#FUSES NOBROWNOUT               //No brownout reset
#FUSES NOLVP                    //No low voltage prgming, B3(PIC16) or B5(PIC18) used for I/O
#use delay(clock=20000000)
#define LCD_RS_PIN      PIN_D1
#define LCD_RW_PIN      PIN_D2
#define LCD_ENABLE_PIN  PIN_D3
#define LCD_DATA4       PIN_D4
#define LCD_DATA5       PIN_D5
#define LCD_DATA6       PIN_D6
#define LCD_DATA7       PIN_D7
#include <lcd.c>
#include <stdlib.h>
#include <math.h>
int uartFlg=0;
int state=0;     // Define working state    
int16 ovrflow=0;
int countchar=0;
int posf=0;
char UART_Buffer;   
char str[12];

#byte TRISC=0x87  
#byte TRISD=0x88
#byte PORTC=0x07
#byte TXREG=0x19

#byte TXSTA=0x98
#bit TRMT=TXSTA.1 
#bit BRGH=TXSTA.2 
#bit SYNC=TXSTA.4 
#bit TXEN=TXSTA.5 

#byte RCSTA=0x18
#bit CREN=RCSTA.4 
#bit SPEN=RCSTA.7

#byte SPBRG=0x99 
#byte RCREG=0x1A

#byte PIE1=0x8C
#bit RCIE=PIE1.5
#bit TMR1IE=PIE1.0

#byte INTCON=0x0B
#bit PEIE=INTCON.6
#bit GIE=INTCON.7

#byte T1CON=0x10
#bit TMR1ON=T1CON.0
#byte TMR1L=0x0E
#byte TMR1H=0x0F

void uart_send_c(char data) 
{
   while(!TRMT);
   TXREG=data;
}

void uart_send_s(char *text)
{
   int i;
   for(i=0;text[i]!='\0';i++)
   uart_send_c(text[i]);
   uart_send_c('\r');
}

void uart_init()
{
   BRGH=1; // High speed, asynchronous mode
   SPBRG=129; // Baudrate 9600 bps
   SYNC=0;
   SPEN=1;  
   RCIE=1;   
   PEIE=1; 
   GIE=1;    
   CREN=1; // Enable data reception
   TXEN=1; // Enable UART transmission 
}

void interrupt_init()
{
   GIE=1;
   PEIE=1;
   TMR1IE=1;
}

#int_timer1
void ngatt1()
{
   ovrflow+=1;
   TMR1L=0;
   TMR1H=0;
}

#int_rda
void uart(){
   UART_buffer=RCREG;  
   if(UART_buffer>=32)   //Sort for character with decimal value >=32
   {
      if(UART_buffer==38) posf=1;
      str[countchar]=UART_buffer;
      countchar+=1;  
   }
   if(posf==1)  //A number is fully received!
   {
      str[countchar-1]=0;
      countchar=0;
      if(str[0]==35)
      {
         str[0]='0';
         state=1;
      }
      uartFlg=1;
      posf=0;
   }
}
void main()
{
   TRISC=0b11000000;
   TRISD=0x00;
   lcd_init();
   uart_init();
   interrupt_init();
   
   lcd_putc('\f');
   lcd_gotoxy(1,1);
   lcd_putc("Ready!");
       
   float kp=0.5,ki=0.9,kd=0.006,tsamp=0.01;   //Define PID parameters
   float setpoint=0,volt=0,pwm=0,in_speed=0,sec;
   float integral=0,last_error=0,error=0,derivative=0;
   char pwmval[11];  
   int16 count=0,duration=10;  // Different from 0 to avoid auto reset
   int32 timecount;
   
   while(TRUE)
   {        
      if((uartFlg==1)&&(state==0))  //Receiving simulation time from GUI
      {
         duration=atoi(str);
         duration*=100;            
         uartFlg=0;
         state=1;      
      }
      if((uartFlg==1)&&(state==1))  //Receiving set point value from GUI
      {
         setpoint=atof(str);
         uartFlg=0;
         state=2;      
      }
      if((uartFlg==1)&&(state==2))  //Receiving feedback speed 
      {
         TMR1L=0;
         TMR1H=0;
         ovrflow=0;
         TMR1ON=1;   // Start counting sampling time
         in_speed=atof(str);
         count+=1;
         uartFlg=2;        
         error=setpoint-in_speed;   
         derivative=(error-last_error)/tsamp;
         integral+=error*tsamp;
         last_error=error;
         volt=kp*error+ki*integral+kd*derivative;         
         pwm=1023*volt/12.0;  //Scale to PWM value 
         if(pwm>1023) pwm=1023;  
         if(pwm<-1023) pwm=-1023;
      }
      if((uartFlg==2)&&(state==2))  //Send PWM value to the motor model
      {   
         sprintf(pwmval,"%.3f",pwm);       
         uart_send_s(pwmval);
         uartFlg=0;
         TMR1ON=0;   // Stop counting sampling time
         timecount=(((int16)TMR1H<<8)|TMR1L)+ovrflow*65536;   
         sec=timecount*1.0/5000000;   
         lcd_gotoxy(5,1);
         printf(lcd_putc,"          ");
         lcd_gotoxy(1,1);
         printf(lcd_putc,"PWM:%.2f",pwm);  
         lcd_gotoxy(1,2);
         printf(lcd_putc,"Tsamp:%.3f",sec);        
      }  
      if(count==duration) //Reset variables after simulation has finished
      {
         lcd_putc('\f');
         lcd_gotoxy(1,1);
         lcd_putc("Ready!");
         setpoint=0;
         volt=0;
         in_speed=0;
         integral=0;
         last_error=0;
         error=0;
         derivative=0;
         state=0;
         count=0;
      }
   }
}
