;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; GNU GENERAL PUBLIC LICENSE ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; CoolWorld
;; CoolWorld is an agent-based model designed to
;; illustrate the usefulness of the theory of Markov chains
;; to analyse computer models.
;; Copyright (C) 2008 Luis R. Izquierdo, Segismundo S. Izquierdo,
;; Jose M. Galan & Jose I. Santos
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
;;
;; Contact information:
;; Luis R. Izquierdo
;;   University of Burgos, Spain.
;;   e-mail: lrizquierdo@ubu.es

;;;;;;;;;;;;;;;;;
;;; VARIABLES ;;;
;;;;;;;;;;;;;;;;;

globals [my-random-seed]

patches-own [
  temperature
  perfect-spot?
  cum-visits  ;; number of times that this patch has been
              ;; visited by a walker
]

;;;;;;;;;;;;;;
;;; BREEDS ;;;
;;;;;;;;;;;;;;

breed [perfect-spots perfect-spot]
breed [walkers walker]

;;;;;;;;;;;;;;;;;;;
;;; MODEL SETUP ;;;
;;;;;;;;;;;;;;;;;;;

to startup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  set my-random-seed new-seed
  random-seed my-random-seed
  setup-patches
end

to set-special-initial-conditions
  reset-ticks clear-drawing clear-all-plots
  clear-turtles clear-patches
  setup-patches
  ask patches [set temperature 100 / ((distancexy 0 0) + 1)]
  ask patches with [distancexy 0 0 >= 5 and distancexy 0 0 < 6] [
    set perfect-spot? true
    sprout-perfect-spots 1 [
      set shape "house"
      set color orange
    ]
  ]
  ask n-of 100 patches [
    sprout-walkers 1 [
      set shape "person"
      set color green
    ]
  ]
  set prob-random-move 0.5
  set prob-leaving-home 0.01
  set pause-at-time-step 50
  with-local-randomness [do-graphs]
end

to setup-patches
  ask patches [
    set temperature 0
    set perfect-spot? false
    set pcolor white
  ]
end

to create-hot-spot
  if mouse-down? [
    ask patch mouse-xcor mouse-ycor [
      set temperature 100
      set pcolor 13
    ]
  ]
  display
end

to diffuse-temperature
  repeat 10 [diffuse temperature 0.5]
  update-patch-colors
end

to create-perfect-spot
  if mouse-down? [
    ask patch mouse-xcor mouse-ycor [
      if not perfect-spot? [
        set perfect-spot? true
        with-local-randomness [
          ;; sprout creates turtles with *random* colours
          ;; and headings (i.e. it uses the pseudo-random
          ;; number generator) but we do not want the random
          ;; state to be altered by the creation of new turtles.
          ;; Thus, we use with-local-randomness to ensure that the creation
          ;; of new turtles does not affect subsequent random events.
          sprout-perfect-spots 1 [
            set shape "house"
            set color orange
          ]
        ]
      ]
    ]
  ]
  display
end

to create-walker
  if mouse-down? [
    ask patch mouse-xcor mouse-ycor [
      if not any? walkers-here [
        with-local-randomness [
          sprout-walkers 1 [
            set shape "person"
            set color green
          ]
        ]
      ]
    ]
  ]
  display
end

;;;;;;;;;;;;;;;;;;;;;;
;;; MAIN PROCEDURE ;;;
;;;;;;;;;;;;;;;;;;;;;;

to go
  ask walkers [walk]
  tick

  with-local-randomness [do-graphs]
    ;; asking an agenset makes use of the pseudo-random number generator

  if ticks = pause-at-time-step [stop]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; WALKERS' PROCEDURES ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

to walk
  ifelse perfect-spot?
   [
     if (random-float 1.0 < prob-leaving-home)
       [move-to one-of neighbors]
   ]
   [
     ifelse (random-float 1.0 < prob-random-move)
       [move-to one-of neighbors]
       [
         let potential-destinations (patch-set patch-here neighbors)
         move-to max-one-of potential-destinations [temperature]
       ]
   ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; GRAPHS AND DATA GATHERING ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to do-graphs
  update-cum-visits
  update-patch-colors
  update-walkers-appearance
  do-plots
end

to update-cum-visits
  ask patches [set cum-visits (cum-visits + count walkers-here)]
end

to update-patch-colors
  ifelse display-mode = "Temperature"
    [ ask patches [set pcolor (13 + 6.99 * ((100 - temperature) / 100) ^ 5)]
        ;; I raise to the power of 5 to make the colour scale finer
        ;; when the temperature is close to 0.
        ;; Using 7 rather than 6.99 can cause patches that should be white turn black
    ]
    [ let min-visits min [cum-visits] of patches
      let max-visits max [cum-visits] of patches
      if (max-visits != min-visits) [
        ask patches [set pcolor (103 + 6.99 * ((max-visits - cum-visits) / (max-visits - min-visits)) ^ 64)]
          ;; I raise to the power of 64 to make the colour scale finer
          ;; when cum-visits is close to min-visits.
          ;; Using 7 rather than 6.99 can cause patches that should be white turn black
      ]
    ]
end

to update-walkers-appearance
  ask walkers [
    ifelse perfect-spot?
     [
       set shape "face happy"
       set label (count walkers-here)
     ]
     [
       set shape "person"
       set label ""
     ]
  ]
end

to do-plots
  set-current-plot "Walkers"
  set-current-plot-pen "wandering"
  plotxy ticks count walkers with [not perfect-spot?]
  set-current-plot-pen "in town"
  plotxy ticks count walkers with [perfect-spot?]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; RANDOM SEED RELATED PROCEDURE ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Use a seed entered by the user
to use-seed-from-user
  let user-seed user-input "Enter a random seed (an integer):"
  if ( user-seed != "" ) [
    set my-random-seed read-from-string user-seed
    random-seed my-random-seed   ;; use the new seed
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
249
10
688
470
16
16
13.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
128
78
219
111
Diffuse heat
with-local-randomness [diffuse-temperature]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
7
78
125
111
Create hot spot
create-hot-spot
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
6
16
69
49
Clear
startup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
7
133
124
166
Create house
create-perfect-spot
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
6
229
196
262
prob-random-move
prob-random-move
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
6
265
196
298
prob-leaving-home
prob-leaving-home
0
0.1
0.01
0.01
1
NIL
HORIZONTAL

BUTTON
6
193
124
226
Create walker
create-walker
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
770
222
841
255
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
5
316
243
466
Walkers
time-step
# walkers
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"wandering" 1.0 0 -16777216 true "" ""
"in town" 1.0 0 -10899396 true "" ""

TEXTBOX
9
62
71
80
Hot Spots
11
0.0
1

TEXTBOX
9
117
67
137
Houses
11
0.0
1

TEXTBOX
9
175
64
193
Walkers
11
0.0
1

CHOOSER
691
312
840
357
display-mode
display-mode
"Temperature" "Visits"
0

BUTTON
127
193
220
226
View / Hide
with-local-randomness [\n  ask walkers [set hidden? not hidden?]\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
127
133
220
166
View / Hide
with-local-randomness [\n  ask perfect-spots [set hidden? not hidden?]\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
692
361
809
394
Update view
with-local-randomness [update-patch-colors]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
692
12
839
45
Change random seed
use-seed-from-user
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
693
48
839
93
Random seed
my-random-seed
17
1
11

SLIDER
692
184
841
217
pause-at-time-step
pause-at-time-step
0
10000
50
1
1
NIL
HORIZONTAL

BUTTON
692
222
767
255
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
692
396
770
429
View ºC
ask patches [set plabel round temperature]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
772
396
850
429
Hide ºC
ask patches [set plabel \"\"]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
696
435
846
470
Fractions of ºC \nare not shown
11
0.0
1

BUTTON
693
96
839
129
Special conditions
set-special-initial-conditions
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="figs_3_4_5" repetitions="100" runMetricsEveryStep="false">
    <setup>set-special-initial-conditions
set pause-at-time-step 51</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count walkers with [perfect-spot?]</metric>
    <enumeratedValueSet variable="display-mode">
      <value value="&quot;Temperature&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-leaving-home">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-random-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pause-at-time-step">
      <value value="51"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="figs_6_7" repetitions="50000" runMetricsEveryStep="false">
    <setup>set-special-initial-conditions
set pause-at-time-step 51</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count walkers with [perfect-spot?]</metric>
    <enumeratedValueSet variable="display-mode">
      <value value="&quot;Temperature&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-leaving-home">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-random-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pause-at-time-step">
      <value value="51"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="fig_12" repetitions="1" runMetricsEveryStep="true">
    <setup>set-special-initial-conditions
set pause-at-time-step 0</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>map [[count walkers-here] of ?] sort patches</metric>
    <enumeratedValueSet variable="display-mode">
      <value value="&quot;Temperature&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-leaving-home">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-random-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pause-at-time-step">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="fig_13" repetitions="1000" runMetricsEveryStep="false">
    <setup>set-special-initial-conditions
set pause-at-time-step 0</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>map [[count walkers-here] of ?] sort patches</metric>
    <enumeratedValueSet variable="display-mode">
      <value value="&quot;Temperature&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-leaving-home">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-random-move">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pause-at-time-step">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
