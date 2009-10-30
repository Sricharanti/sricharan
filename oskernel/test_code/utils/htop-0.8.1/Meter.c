/*
htop - Meter.c
(C) 2004-2006 Hisham H. Muhammad
Released under the GNU GPL, see the COPYING file
in the source distribution for its full text.
*/

#define _GNU_SOURCE
#include <math.h>
#include <string.h>
#include <stdlib.h>
#include <curses.h>
#include <stdarg.h>

#include "Meter.h"
#include "Object.h"
#include "CRT.h"
#include "ListItem.h"
#include "String.h"
#include "ProcessList.h"
#include "RichString.h"

#include "debug.h"
#include <assert.h>

#ifndef USE_FUNKY_MODES
#define USE_FUNKY_MODES 1
#endif

#define METER_BUFFER_LEN 128

/*{

typedef struct Meter_ Meter;
typedef struct MeterType_ MeterType;
typedef struct MeterMode_ MeterMode;

typedef void(*MeterType_Init)(Meter*);
typedef void(*MeterType_Done)(Meter*);
typedef void(*MeterType_SetMode)(Meter*, int);
typedef void(*Meter_SetValues)(Meter*, char*, int);
typedef void(*Meter_Draw)(Meter*, int, int, int);

struct MeterMode_ {
   Meter_Draw draw;
   char* uiName;
   int h;
};

struct MeterType_ {
   Meter_SetValues setValues;
   Object_Display display;
   int mode;
   int items;
   double total;
   int* attributes;
   char* name;
   char* uiName;
   char* caption;
   MeterType_Init init;
   MeterType_Done done;
   MeterType_SetMode setMode;
   Meter_Draw draw;
};

struct Meter_ {
   Object super;
   char* caption;
   MeterType* type;
   int mode;
   int param;
   Meter_Draw draw;
   void* drawBuffer;
   int h;
   ProcessList* pl;
   double* values;
   double total;
};

typedef enum {
   CUSTOM_METERMODE = 0,
   BAR_METERMODE,
   TEXT_METERMODE,
#ifdef USE_FUNKY_MODES
   GRAPH_METERMODE,
   LED_METERMODE,
#endif
   LAST_METERMODE
} MeterModeId;

}*/

#include "CPUMeter.h"
#include "MemoryMeter.h"
#include "SwapMeter.h"
#include "TasksMeter.h"
#include "LoadAverageMeter.h"
#include "UptimeMeter.h"
#include "BatteryMeter.h"
#include "ClockMeter.h"


#ifndef MIN
#define MIN(a,b) ((a)<(b)?(a):(b))
#endif
#ifndef MAX
#define MAX(a,b) ((a)>(b)?(a):(b))
#endif

#ifdef DEBUG
char* METER_CLASS = "Meter";
#else
#define METER_CLASS NULL
#endif

MeterType* Meter_types[] = {
   &CPUMeter,
   &ClockMeter,
   &LoadAverageMeter,
   &LoadMeter,
   &MemoryMeter,
   &SwapMeter,
   &TasksMeter,
   &UptimeMeter,
   &BatteryMeter,
   &AllCPUsMeter,
   NULL
};

static RichString Meter_stringBuffer;

Meter* Meter_new(ProcessList* pl, int param, MeterType* type) {
   Meter* this = calloc(sizeof(Meter), 1);
   Object_setClass(this, METER_CLASS);
   ((Object*)this)->delete = Meter_delete;
   ((Object*)this)->display = type->display;
   this->h = 1;
   this->type = type;
   this->param = param;
   this->pl = pl;
   this->values = calloc(sizeof(double), type->items);
   this->total = type->total;
   this->caption = strdup(type->caption);
   Meter_setMode(this, type->mode);
   if (this->type->init)
      this->type->init(this);
   return this;
}

void Meter_delete(Object* cast) {
   Meter* this = (Meter*) cast;
   assert (this != NULL);
   if (this->type->done) {
      this->type->done(this);
   }
   if (this->drawBuffer)
      free(this->drawBuffer);
   free(this->caption);
   free(this->values);
   free(this);
}

void Meter_setCaption(Meter* this, char* caption) {
   free(this->caption);
   this->caption = strdup(caption);
}

static inline void Meter_displayToStringBuffer(Meter* this, char* buffer) {
   MeterType* type = this->type;
   Object_Display display = ((Object*)this)->display;
   if (display) {
      display((Object*)this, &Meter_stringBuffer);
   } else {
      RichString_initVal(Meter_stringBuffer);
      RichString_append(&Meter_stringBuffer, CRT_colors[type->attributes[0]], buffer);
   }
}

void Meter_setMode(Meter* this, int modeIndex) {
   if (modeIndex > 0 && modeIndex == this->mode)
      return;
   if (!modeIndex)
      modeIndex = 1;
   assert(modeIndex < LAST_METERMODE);
   if (this->type->mode == 0) {
      this->draw = this->type->draw;
      if (this->type->setMode)
         this->type->setMode(this, modeIndex);
   } else {
      assert(modeIndex >= 1);
      if (this->drawBuffer)
         free(this->drawBuffer);
      this->drawBuffer = NULL;

      MeterMode* mode = Meter_modes[modeIndex];
      this->draw = mode->draw;
      this->h = mode->h;
   }
   this->mode = modeIndex;
}

ListItem* Meter_toListItem(Meter* this) {
   MeterType* type = this->type;
   char mode[21];
   if (this->mode)
      snprintf(mode, 20, " [%s]", Meter_modes[this->mode]->uiName);
   else
      mode[0] = '\0';
   char number[11];
   if (this->param > 0)
      snprintf(number, 10, " %d", this->param);
   else
      number[0] = '\0';
   char buffer[51];
   snprintf(buffer, 50, "%s%s%s", type->uiName, number, mode);
   return ListItem_new(buffer, 0);
}

/* ---------- TextMeterMode ---------- */

static void TextMeterMode_draw(Meter* this, int x, int y, int w) {
   MeterType* type = this->type;
   char buffer[METER_BUFFER_LEN];
   type->setValues(this, buffer, METER_BUFFER_LEN - 1);

   attrset(CRT_colors[METER_TEXT]);
   mvaddstr(y, x, this->caption);
   int captionLen = strlen(this->caption);
   w -= captionLen;
   x += captionLen;
   Meter_displayToStringBuffer(this, buffer);
   mvhline(y, x, ' ', CRT_colors[DEFAULT_COLOR]);
   attrset(CRT_colors[RESET_COLOR]);
   RichString_printVal(Meter_stringBuffer, y, x);
}

/* ---------- BarMeterMode ---------- */

static char BarMeterMode_characters[] = "|#*@$%&";

static void BarMeterMode_draw(Meter* this, int x, int y, int w) {
   MeterType* type = this->type;
   char buffer[METER_BUFFER_LEN];
   type->setValues(this, buffer, METER_BUFFER_LEN - 1);

   w -= 2;
   attrset(CRT_colors[METER_TEXT]);
   int captionLen = 3;
   mvaddnstr(y, x, this->caption, captionLen);
   x += captionLen;
   w -= captionLen;
   attrset(CRT_colors[BAR_BORDER]);
   mvaddch(y, x, '[');
   mvaddch(y, x + w, ']');
   
   w--;
   x++;
   char bar[w];
   
   int blockSizes[10];
   for (int i = 0; i < w; i++)
      bar[i] = ' ';

   sprintf(bar + (w-strlen(buffer)), "%s", buffer);

   // First draw in the bar[] buffer...
   double total = 0.0;
   int offset = 0;
   for (int i = 0; i < type->items; i++) {
      double value = this->values[i];
      value = MAX(value, 0);
      value = MIN(value, this->total);
      if (value > 0) {
         blockSizes[i] = ceil((value/this->total) * w);
      } else {
         blockSizes[i] = 0;
      }
      int nextOffset = offset + blockSizes[i];
      // (Control against invalid values)
      nextOffset = MIN(MAX(nextOffset, 0), w);
      for (int j = offset; j < nextOffset; j++)
         if (bar[j] == ' ') {
            if (CRT_colorScheme == COLORSCHEME_MONOCHROME) {
               bar[j] = BarMeterMode_characters[i];
            } else {
               bar[j] = '|';
            }
         }
      offset = nextOffset;
      total += this->values[i];
   }

   // ...then print the buffer.
   offset = 0;
   for (int i = 0; i < type->items; i++) {
      attrset(CRT_colors[type->attributes[i]]);
      mvaddnstr(y, x + offset, bar + offset, blockSizes[i]);
      offset += blockSizes[i];
      offset = MAX(offset, 0);
      offset = MIN(offset, w);
   }
   if (offset < w) {
      attrset(CRT_colors[BAR_SHADOW]);
      mvaddnstr(y, x + offset, bar + offset, w - offset);
   }

   move(y, x + w + 1);
   attrset(CRT_colors[RESET_COLOR]);
}

#ifdef USE_FUNKY_MODES

/* ---------- GraphMeterMode ---------- */

#define DrawDot(a,y,c) do { attrset(a); mvaddch(y, x+k, c); } while(0)

static int GraphMeterMode_colors[21] = {
   GRAPH_1, GRAPH_1, GRAPH_1,
   GRAPH_2, GRAPH_2, GRAPH_2,
   GRAPH_3, GRAPH_3, GRAPH_3,
   GRAPH_4, GRAPH_4, GRAPH_4,
   GRAPH_5, GRAPH_5, GRAPH_6,
   GRAPH_7, GRAPH_7, GRAPH_7,
   GRAPH_8, GRAPH_8, GRAPH_9
};

static char* GraphMeterMode_characters = "^`'-.,_~'`-.,_~'`-.,_";

static void GraphMeterMode_draw(Meter* this, int x, int y, int w) {

   if (!this->drawBuffer) this->drawBuffer = calloc(sizeof(double), METER_BUFFER_LEN);
   double* drawBuffer = (double*) this->drawBuffer;

   for (int i = 0; i < METER_BUFFER_LEN - 1; i++)
      drawBuffer[i] = drawBuffer[i+1];

   MeterType* type = this->type;
   char buffer[METER_BUFFER_LEN];
   type->setValues(this, buffer, METER_BUFFER_LEN - 1);

   double value = 0.0;
   for (int i = 0; i < type->items; i++)
      value += this->values[i];
   value /= this->total;
   drawBuffer[METER_BUFFER_LEN - 1] = value;
   for (int i = METER_BUFFER_LEN - w, k = 0; i < METER_BUFFER_LEN; i++, k++) {
      double value = drawBuffer[i];
      DrawDot( CRT_colors[DEFAULT_COLOR], y, ' ' );
      DrawDot( CRT_colors[DEFAULT_COLOR], y+1, ' ' );
      DrawDot( CRT_colors[DEFAULT_COLOR], y+2, ' ' );
      
      double threshold = 1.00;
      for (int i = 0; i < 21; i++, threshold -= 0.05)
         if (value >= threshold) {
            DrawDot(CRT_colors[GraphMeterMode_colors[i]], y+(i/7.0), GraphMeterMode_characters[i]);
            break;
         }
   }
   attrset(CRT_colors[RESET_COLOR]);
}

/* ---------- LEDMeterMode ---------- */

static char* LEDMeterMode_digits[3][10] = {
   { " __ ","    "," __ "," __ ","    "," __ "," __ "," __ "," __ "," __ "},
   { "|  |","   |"," __|"," __|","|__|","|__ ","|__ ","   |","|__|","|__|"},
   { "|__|","   |","|__ "," __|","   |"," __|","|__|","   |","|__|"," __|"},
};

static void LEDMeterMode_drawDigit(int x, int y, int n) {
   for (int i = 0; i < 3; i++)
      mvaddstr(y+i, x, LEDMeterMode_digits[i][n]);
}

static void LEDMeterMode_draw(Meter* this, int x, int y, int w) {
   MeterType* type = this->type;
   char buffer[METER_BUFFER_LEN];
   type->setValues(this, buffer, METER_BUFFER_LEN - 1);
  
   Meter_displayToStringBuffer(this, buffer);

   attrset(CRT_colors[LED_COLOR]);
   mvaddstr(y+2, x, this->caption);
   int xx = x + strlen(this->caption);
   for (int i = 0; i < Meter_stringBuffer.len; i++) {
      char c = RichString_getCharVal(Meter_stringBuffer, i);
      if (c >= '0' && c <= '9') {
         LEDMeterMode_drawDigit(xx, y, c-48);
         xx += 4;
      } else {
         mvaddch(y+2, xx, c);
         xx += 1;
      }
   }
   attrset(CRT_colors[RESET_COLOR]);
}

#endif

static MeterMode BarMeterMode = {
   .uiName = "Bar",
   .h = 1,
   .draw = BarMeterMode_draw,
};

static MeterMode TextMeterMode = {
   .uiName = "Text",
   .h = 1,
   .draw = TextMeterMode_draw,
};

#ifdef USE_FUNKY_MODES

static MeterMode GraphMeterMode = {
   .uiName = "Graph",
   .h = 3,
   .draw = GraphMeterMode_draw,
};

static MeterMode LEDMeterMode = {
   .uiName = "LED",
   .h = 3,
   .draw = LEDMeterMode_draw,
};

#endif

MeterMode* Meter_modes[] = {
   NULL,
   &BarMeterMode,
   &TextMeterMode,
#ifdef USE_FUNKY_MODES
   &GraphMeterMode,
   &LEDMeterMode,
#endif
   NULL
};
