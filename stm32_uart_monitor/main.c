/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body - Simple UART Data Monitor
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2026 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <ctype.h>
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
#define RX_BUFFER_SIZE 512
#define RX_TIMEOUT_MS 100    // 100ms timeout to detect packet end
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/

COM_InitTypeDef BspCOMInit;
__IO uint32_t BspButtonState = BUTTON_RELEASED;

UART_HandleTypeDef huart2;

/* USER CODE BEGIN PV */
uint32_t counter = 0;
char uart_buffer[50];
uint8_t rx_buffer[RX_BUFFER_SIZE];
uint16_t rx_index = 0;
uint32_t last_rx_time = 0;
uint32_t last_send_time = 0;
uint32_t packet_count = 0;
uint32_t total_bytes_received = 0;
uint8_t receiving_data = 0;
/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MPU_Config(void);
static void MX_GPIO_Init(void);
static void MX_USART2_UART_Init(void);
/* USER CODE BEGIN PFP */
void display_uart_data(uint8_t *data, uint16_t len);
/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */

/**
  * @brief  Display all incoming UART data in multiple formats
  * @param  data: pointer to data buffer
  * @param  len: length of data
  * @retval None
  */
void display_uart_data(uint8_t *data, uint16_t len)
{
  if (len == 0) return;

  packet_count++;
  total_bytes_received += len;

  printf("\r\n");
  printf("╔════════════════════════════════════════════════════════════════╗\r\n");
  printf("║ UART RX #%-5lu | Size: %-5d bytes | Total: %-8lu bytes  ║\r\n", 
         packet_count, len, total_bytes_received);
  printf("╠════════════════════════════════════════════════════════════════╣\r\n");

  // Display HEX dump (16 bytes per line with offset)
  printf("║ HEX DUMP:                                                      ║\r\n");
  for (uint16_t i = 0; i < len; i += 16)
  {
    // Print offset
    printf("║ %04X: ", i);
    
    // Print hex bytes
    for (uint16_t j = 0; j < 16; j++)
    {
      if (i + j < len)
      {
        printf("%02X ", data[i + j]);
      }
      else
      {
        printf("   ");
      }
      
      // Add separator at middle
      if (j == 7)
      {
        printf(" ");
      }
    }
    
    printf(" | ");
    
    // Print ASCII representation
    for (uint16_t j = 0; j < 16 && i + j < len; j++)
    {
      uint8_t c = data[i + j];
      if (isprint(c))
      {
        printf("%c", c);
      }
      else if (c == '\r')
      {
        printf("↵");
      }
      else if (c == '\n')
      {
        printf("↲");
      }
      else if (c == '\t')
      {
        printf("→");
      }
      else
      {
        printf(".");
      }
    }
    
    // Pad to align the right edge
    uint16_t remaining = 16 - (len - i > 16 ? 16 : len - i);
    for (uint16_t j = 0; j < remaining; j++)
    {
      printf(" ");
    }
    
    printf(" ║\r\n");
  }

  // Display raw ASCII/text interpretation
  printf("╠════════════════════════════════════════════════════════════════╣\r\n");
  printf("║ ASCII/TEXT VIEW:                                               ║\r\n");
  printf("║ ");
  
  uint16_t line_pos = 1;
  for (uint16_t i = 0; i < len; i++)
  {
    uint8_t c = data[i];
    
    if (c == '\r')
    {
      printf("\\r");
      line_pos += 2;
    }
    else if (c == '\n')
    {
      printf("\\n");
      line_pos += 2;
      // Start new line in display
      while (line_pos < 62)
      {
        printf(" ");
        line_pos++;
      }
      printf(" ║\r\n║ ");
      line_pos = 1;
    }
    else if (c == '\t')
    {
      printf("\\t");
      line_pos += 2;
    }
    else if (isprint(c))
    {
      printf("%c", c);
      line_pos++;
    }
    else
    {
      printf("\\x%02X", c);
      line_pos += 4;
    }
    
    // Wrap line if needed
    if (line_pos >= 62 && i < len - 1)
    {
      while (line_pos < 62)
      {
        printf(" ");
        line_pos++;
      }
      printf(" ║\r\n║ ");
      line_pos = 1;
    }
  }
  
  // Pad last line
  while (line_pos < 62)
  {
    printf(" ");
    line_pos++;
  }
  printf(" ║\r\n");

  // Display raw byte values (decimal)
  printf("╠════════════════════════════════════════════════════════════════╣\r\n");
  printf("║ DECIMAL VALUES: ");
  for (uint16_t i = 0; i < len && i < 15; i++)
  {
    printf("%3d ", data[i]);
  }
  if (len > 15)
  {
    printf("...                         ║\r\n");
  }
  else
  {
    uint16_t padding = 15 - len;
    for (uint16_t i = 0; i < padding; i++)
    {
      printf("    ");
    }
    printf("   ║\r\n");
  }

  printf("╚════════════════════════════════════════════════════════════════╝\r\n");
  printf("\r\n");

  // Toggle YELLOW LED to indicate packet displayed
  BSP_LED_Toggle(LED_YELLOW);
}

/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{

  /* USER CODE BEGIN 1 */

  /* USER CODE END 1 */

  /* MPU Configuration--------------------------------------------------------*/
  MPU_Config();

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_USART2_UART_Init();
  /* USER CODE BEGIN 2 */

  /* USER CODE END 2 */

  /* Initialize leds */
  BSP_LED_Init(LED_GREEN);
  BSP_LED_Init(LED_YELLOW);
  BSP_LED_Init(LED_RED);

  /* Initialize USER push-button, will be used to trigger an interrupt each time it's pressed.*/
  BSP_PB_Init(BUTTON_USER, BUTTON_MODE_EXTI);

  /* Initialize COM1 port (115200, 8 bits (7-bit data + 1 stop bit), no parity */
  BspCOMInit.BaudRate   = 115200;
  BspCOMInit.WordLength = COM_WORDLENGTH_8B;
  BspCOMInit.StopBits   = COM_STOPBITS_1;
  BspCOMInit.Parity     = COM_PARITY_NONE;
  BspCOMInit.HwFlowCtl  = COM_HWCONTROL_NONE;
  if (BSP_COM_Init(COM1, &BspCOMInit) != BSP_ERROR_NONE)
  {
    Error_Handler();
  }

  /* USER CODE BEGIN BSP */

  /* -- Sample board code to send message over COM1 port ---- */
  printf("\r\n\r\n");
  printf("╔════════════════════════════════════════════════════════════════╗\r\n");
  printf("║          STM32 UART Data Monitor - READY                      ║\r\n");
  printf("╠════════════════════════════════════════════════════════════════╣\r\n");
  printf("║ Mode:       RECEIVE ONLY (no transmission on USART2)          ║\r\n");
  printf("║ Monitoring: USART2 @ 115200 baud                              ║\r\n");
  printf("║ Displays:   HEX, ASCII, Decimal for ALL incoming data         ║\r\n");
  printf("║ Heartbeat:  Every 5 seconds (LED only)                        ║\r\n");
  printf("║ LED Red:    Receiving data                                    ║\r\n");
  printf("║ LED Yellow: Data displayed                                    ║\r\n");
  printf("║ LED Green:  Heartbeat                                         ║\r\n");
  printf("╚════════════════════════════════════════════════════════════════╝\r\n");
  printf("\r\n");

  /* -- Sample board code to switch on leds ---- */
  BSP_LED_On(LED_GREEN);
  HAL_Delay(200);
  BSP_LED_Off(LED_GREEN);
  BSP_LED_On(LED_YELLOW);
  HAL_Delay(200);
  BSP_LED_Off(LED_YELLOW);
  BSP_LED_On(LED_RED);
  HAL_Delay(200);
  BSP_LED_Off(LED_RED);

  /* USER CODE END BSP */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  uint8_t rx_byte;
  last_send_time = HAL_GetTick();

  printf("[SYSTEM] Waiting for UART data...\r\n\r\n");

  while (1)
  {
    /* Check for incoming data on UART */
    if (HAL_UART_Receive(&huart2, &rx_byte, 1, 10) == HAL_OK)
    {
      // Data received
      if (!receiving_data)
      {
        // First byte of new packet
        receiving_data = 1;
        BSP_LED_On(LED_RED);  // RED LED indicates receiving
      }

      // Store byte in buffer
      if (rx_index < RX_BUFFER_SIZE)
      {
        rx_buffer[rx_index++] = rx_byte;
        last_rx_time = HAL_GetTick();
      }
      else
      {
        // Buffer full, display immediately
        BSP_LED_Off(LED_RED);
        display_uart_data(rx_buffer, rx_index);
        rx_index = 0;
        receiving_data = 0;
      }
    }
    else
    {
      // No data received, check for timeout
      if (receiving_data && rx_index > 0)
      {
        uint32_t time_since_last_rx = HAL_GetTick() - last_rx_time;
        if (time_since_last_rx >= RX_TIMEOUT_MS)
        {
          // Timeout - packet complete
          BSP_LED_Off(LED_RED);
          display_uart_data(rx_buffer, rx_index);
          rx_index = 0;
          receiving_data = 0;
        }
      }
    }
    
    /* Heartbeat - LED only, no UART transmission (receive-only mode) */
    if (HAL_GetTick() - last_send_time >= 5000)
    {
      /* Toggle GREEN LED to indicate heartbeat */
      BSP_LED_Toggle(LED_GREEN);

      /* Print status to debug console (COM1) only */
      printf("[HEARTBEAT] Counter: %lu | Packets: %lu | Bytes: %lu\r\n", 
             counter, packet_count, total_bytes_received);

      counter++;
      last_send_time = HAL_GetTick();
    }

    /* -- Sample board code for User push-button in interrupt mode ---- */
    if (BspButtonState == BUTTON_PRESSED)
    {
      /* Update button state */
      BspButtonState = BUTTON_RELEASED;

      /* Toggle all LEDs and print status */
      BSP_LED_Toggle(LED_GREEN);
      BSP_LED_Toggle(LED_YELLOW);
      BSP_LED_Toggle(LED_RED);

      printf("\r\n");
      printf("╔════════════════════════════════════════════════════════════════╗\r\n");
      printf("║ [BUTTON] User Button Pressed - Statistics:                    ║\r\n");
      printf("╠════════════════════════════════════════════════════════════════╣\r\n");
      printf("║ Packets Received:  %-8lu                                   ║\r\n", packet_count);
      printf("║ Total Bytes:       %-8lu                                   ║\r\n", total_bytes_received);
      printf("║ Uptime Seconds:    %-8lu                                   ║\r\n", HAL_GetTick() / 1000);
      printf("╚════════════════════════════════════════════════════════════════╝\r\n");
      printf("\r\n");
    }
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /*AXI clock gating */
  RCC->CKGAENR = 0xE003FFFF;

  /** Supply configuration update enable
  */
  HAL_PWREx_ConfigSupply(PWR_DIRECT_SMPS_SUPPLY);

  /** Configure the main internal regulator output voltage
  */
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE0);

  while(!__HAL_PWR_GET_FLAG(PWR_FLAG_VOSRDY)) {}

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
  RCC_OscInitStruct.HSIState = RCC_HSI_DIV1;
  RCC_OscInitStruct.HSICalibrationValue = 64;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSI;
  RCC_OscInitStruct.PLL.PLLM = 4;
  RCC_OscInitStruct.PLL.PLLN = 8;
  RCC_OscInitStruct.PLL.PLLP = 2;
  RCC_OscInitStruct.PLL.PLLQ = 4;
  RCC_OscInitStruct.PLL.PLLR = 2;
  RCC_OscInitStruct.PLL.PLLRGE = RCC_PLL1VCIRANGE_3;
  RCC_OscInitStruct.PLL.PLLVCOSEL = RCC_PLL1VCOWIDE;
  RCC_OscInitStruct.PLL.PLLFRACN = 0;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2
                              |RCC_CLOCKTYPE_D3PCLK1|RCC_CLOCKTYPE_D1PCLK1;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.SYSCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_HCLK_DIV1;
  RCC_ClkInitStruct.APB3CLKDivider = RCC_APB3_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_APB1_DIV1;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_APB2_DIV1;
  RCC_ClkInitStruct.APB4CLKDivider = RCC_APB4_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_1) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief USART2 Initialization Function
  * @param None
  * @retval None
  */
static void MX_USART2_UART_Init(void)
{

  /* USER CODE BEGIN USART2_Init 0 */

  /* USER CODE END USART2_Init 0 */

  /* USER CODE BEGIN USART2_Init 1 */

  /* USER CODE END USART2_Init 1 */
  huart2.Instance = USART2;
  huart2.Init.BaudRate = 115200;
  huart2.Init.WordLength = UART_WORDLENGTH_8B;
  huart2.Init.StopBits = UART_STOPBITS_1;
  huart2.Init.Parity = UART_PARITY_NONE;
  huart2.Init.Mode = UART_MODE_TX_RX;
  huart2.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart2.Init.OverSampling = UART_OVERSAMPLING_16;
  huart2.Init.OneBitSampling = UART_ONE_BIT_SAMPLE_DISABLE;
  huart2.Init.ClockPrescaler = UART_PRESCALER_DIV1;
  huart2.AdvancedInit.AdvFeatureInit = UART_ADVFEATURE_NO_INIT;
  if (HAL_UART_Init(&huart2) != HAL_OK)
  {
    Error_Handler();
  }
  if (HAL_UARTEx_SetTxFifoThreshold(&huart2, UART_TXFIFO_THRESHOLD_1_8) != HAL_OK)
  {
    Error_Handler();
  }
  if (HAL_UARTEx_SetRxFifoThreshold(&huart2, UART_RXFIFO_THRESHOLD_1_8) != HAL_OK)
  {
    Error_Handler();
  }
  if (HAL_UARTEx_DisableFifoMode(&huart2) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN USART2_Init 2 */

  /* USER CODE END USART2_Init 2 */

}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
  /* USER CODE BEGIN MX_GPIO_Init_1 */

  /* USER CODE END MX_GPIO_Init_1 */

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOC_CLK_ENABLE();
  __HAL_RCC_GPIOH_CLK_ENABLE();
  __HAL_RCC_GPIOA_CLK_ENABLE();

  /* USER CODE BEGIN MX_GPIO_Init_2 */

  /* USER CODE END MX_GPIO_Init_2 */
}

/* USER CODE BEGIN 4 */

/* USER CODE END 4 */

 /* MPU Configuration */

void MPU_Config(void)
{
  MPU_Region_InitTypeDef MPU_InitStruct = {0};

  /* Disables the MPU */
  HAL_MPU_Disable();

  /** Initializes and configures the Region and the memory to be protected
  */
  MPU_InitStruct.Enable = MPU_REGION_ENABLE;
  MPU_InitStruct.Number = MPU_REGION_NUMBER0;
  MPU_InitStruct.BaseAddress = 0x0;
  MPU_InitStruct.Size = MPU_REGION_SIZE_4GB;
  MPU_InitStruct.SubRegionDisable = 0x87;
  MPU_InitStruct.TypeExtField = MPU_TEX_LEVEL0;
  MPU_InitStruct.AccessPermission = MPU_REGION_NO_ACCESS;
  MPU_InitStruct.DisableExec = MPU_INSTRUCTION_ACCESS_DISABLE;
  MPU_InitStruct.IsShareable = MPU_ACCESS_SHAREABLE;
  MPU_InitStruct.IsCacheable = MPU_ACCESS_NOT_CACHEABLE;
  MPU_InitStruct.IsBufferable = MPU_ACCESS_NOT_BUFFERABLE;

  HAL_MPU_ConfigRegion(&MPU_InitStruct);
  /* Enables the MPU */
  HAL_MPU_Enable(MPU_PRIVILEGED_DEFAULT);

}

/**
  * @brief BSP Push Button callback
  * @param Button Specifies the pressed button
  * @retval None
  */
void BSP_PB_Callback(Button_TypeDef Button)
{
  if (Button == BUTTON_USER)
  {
    BspButtonState = BUTTON_PRESSED;
  }
}

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}

#ifdef USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
