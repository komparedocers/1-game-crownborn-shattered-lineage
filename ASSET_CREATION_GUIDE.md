# Asset Creation Guide

This guide explains how to create the 3D models, textures, and audio files for Crownborn: Shattered Lineage.

## Overview

The game currently uses **placeholder procedural assets**. To make the game production-ready, you need to create:

1. **3D Models** - Characters, enemies, weapons, environments
2. **Textures** - Materials for all 3D models
3. **Audio Files** - Music, SFX, voice lines
4. **Animations** - Character movements, attacks, etc.

---

## 1. 3D Asset Creation in Blender

### Prerequisites
- **Blender 3.6+** (Free, open source)
- Basic 3D modeling knowledge
- Understanding of game-ready asset optimization

### A. Character Models

#### Player Character (Boy/Girl Variants)

**Specifications:**
- **Polycount**: 3,000-5,000 triangles
- **Height**: ~1.8m (Blender units)
- **Rigging**: Humanoid skeleton (for animations)
- **LOD Levels**: 3 (High, Medium, Low)

**Assets to Create:**
1. **Body mesh** - Humanoid character
2. **Head** with facial features
3. **Clothing** (adventure gear)
4. **Hair/Helmet**

**Export Format:** `.glb` or `.gltf`

**Blender Workflow:**
```
1. Model character in Edit Mode
2. UV Unwrap (U > Smart UV Project)
3. Create armature (Shift+A > Armature)
4. Weight paint bones to mesh
5. Test animations
6. Export: File > Export > glTF 2.0
   - Format: glTF Binary (.glb)
   - Include: Selected Objects, Animations
```

**File Location:** Export to `android-game/godot-project/assets/models/characters/`

---

#### Enemy Models

**Soldier Enemy:**
- Polycount: 2,000-3,000 triangles
- Armor variations (light/medium/heavy)
- Weapon attachments (sword, bow)

**Animal Enemies:**
- **Wolf**: 1,500-2,500 triangles, quadruped rig
- **Bear**: 2,000-3,000 triangles, larger quadruped
- **Eagle**: 1,000-2,000 triangles, flight rig

**Elite Enemies:**
- Polycount: 3,000-4,000 triangles
- More detailed armor
- Unique weapons

---

#### Boss Models

**Specifications:**
- Polycount: 5,000-8,000 triangles
- Multiple materials (armor, skin, effects)
- Larger scale (2.5-3m tall)
- Weak points visually distinct

**Boss Examples:**
- **General Krath**: Armored warrior with storm effects
- **Matron Vess**: Mirror-adorned sorceress
- **High Warlock Zev**: Chanting priest with mystic symbols

---

### B. Weapon Models

**Required Weapons:**

1. **Sword**
   - Polycount: 500-800 triangles
   - Blade + Handle + Guard
   - Metallic material

2. **Knife**
   - Polycount: 200-400 triangles
   - Short blade, leather grip

3. **Auto-Bow**
   - Polycount: 600-1,000 triangles
   - Curved limbs, string
   - Mechanical components

4. **Repeater Arbalest** (Shop weapon)
   - Polycount: 800-1,200 triangles
   - Crossbow design with auto-reload

5. **Storm Chakram**
   - Polycount: 400-600 triangles
   - Circular blade with lightning effects

6. **Viper Blade**
   - Polycount: 500-800 triangles
   - Poison drip effects

**Export:** Each weapon as separate `.glb` file

---

### C. Environment Assets

**Buildings:**
- Various sizes (small hut to large fortress)
- Modular pieces (walls, roofs, doors)
- Polycount: 1,000-5,000 per building

**Props:**
- Crates, barrels, tables, chairs
- Polycount: 100-500 each
- Instances for optimization

**Terrain Features:**
- Trees, rocks, vegetation
- LOD levels for distant objects

**Secret Passages:**
- Vent grates
- Sewer entrances
- Rafters
- Climbable ivy

---

### D. Blender to Godot Pipeline

**Step-by-Step:**

1. **Model in Blender**
   - Use real-world scale (1 Blender unit = 1 meter)
   - Keep origin at base of model

2. **UV Unwrap**
   - Mark seams (Ctrl+E > Mark Seam)
   - Unwrap (U > Unwrap)
   - Optimize UV layout for texture atlas

3. **Texture Painting** (Optional in Blender)
   - Switch to Texture Paint workspace
   - Create base textures
   - Export textures as PNG

4. **Rigging** (For animated objects)
   - Add Armature (Shift+A > Armature)
   - Parent mesh to armature (Ctrl+P > Automatic Weights)
   - Test with pose mode

5. **Export Settings**
   ```
   File > Export > glTF 2.0 (.glb)

   Settings:
   - Format: glTF Binary (.glb)
   - Include: Selected Objects
   - Transform: +Y Up
   - Geometry: Apply Modifiers, UVs, Normals
   - Materials: Export
   - Animation: Animation, Shape Keys
   ```

6. **Import to Godot**
   - Copy `.glb` to Godot assets folder
   - Godot auto-imports on file detection
   - Configure in Import dock:
     - Meshes: Generate Lightmap UVs
     - Materials: Use External
     - Animation: Enable

---

## 2. Texture Creation

### A. Texture Types Needed

1. **Albedo/Diffuse** - Base color
2. **Normal Map** - Surface details
3. **Roughness** - Surface shininess
4. **Metallic** - Metal vs non-metal
5. **Ambient Occlusion** - Shadow detail

### B. Tools

**Free Options:**
- **Krita** - 2D painting (free)
- **GIMP** - Image editing (free)
- **ArmorPaint** - PBR texture painting (free)
- **Blender Texture Paint** - Built-in

**Paid Options:**
- **Substance Painter** - Industry standard
- **Photoshop** - Professional editing

### C. Texture Specifications

**Resolution:**
- Characters: 2048x2048 (main) down to 512x512 (LOD3)
- Weapons: 1024x1024
- Props: 512x512 to 1024x1024
- Environment: 2048x2048 (tiling)

**Format:** PNG (for alpha) or JPG (for opaque)

**Mobile Optimization:**
- Use texture atlases when possible
- Compress textures (ASTC for Android, PVRTC for iOS)
- Godot handles compression on export

### D. Creating Textures

**In Krita/GIMP:**

1. Create new image (2048x2048)
2. Paint base colors
3. Add details (dirt, scratches, patterns)
4. Export as PNG

**In Substance Painter:**

1. Import `.glb` model
2. Add materials and textures
3. Paint details
4. Bake maps (Normal, AO, Curvature)
5. Export texture set:
   - Albedo
   - Normal
   - Metallic
   - Roughness
   - AO

**File Location:** `android-game/godot-project/assets/textures/`

---

## 3. Audio Asset Creation

### A. Music Tracks

**Required Tracks:**

1. **Menu Theme** (2-3 minutes, looping)
   - Style: Orchestral, epic
   - Tempo: Moderate
   - Mood: Hopeful, adventurous

2. **Combat Theme** (3-4 minutes, looping)
   - Style: Action, intense
   - Tempo: Fast
   - Mood: Tense, energetic

3. **Boss Theme** (4-5 minutes, looping)
   - Style: Epic orchestral
   - Tempo: Variable (dynamic)
   - Mood: Dramatic, threatening

4. **Victory Theme** (30 seconds, one-shot)
   - Style: Triumphant fanfare
   - Mood: Celebratory

**Tools:**
- **LMMS** (Free DAW)
- **Reaper** (Affordable DAW)
- **FL Studio** (Professional DAW)
- **Free Music Archive** (royalty-free music)

**Format:** OGG Vorbis (best for Godot)
**Sample Rate:** 44.1 kHz
**Bitrate:** 128-192 kbps

**Export Location:** `android-game/godot-project/audio/music/`

---

### B. Sound Effects (SFX)

**Categories Needed:**

**Combat SFX:**
- Sword swing (whoosh)
- Sword hit (clang)
- Arrow fire (twang)
- Arrow impact (thud)
- Knife stab (squelch)

**Player SFX:**
- Footsteps (stone, grass, wood)
- Jump
- Landing
- Take damage (grunt)
- Death (scream)

**Power SFX:**
- Blink Step (teleport sound)
- Shadow Veil (stealth activation)
- Time Slip (slow-mo effect)
- Each of 13 powers needs unique sound

**Enemy SFX:**
- Alert sound
- Death sound
- Attack sounds

**Boss SFX:**
- Roar
- Phase change
- Special attacks

**UI SFX:**
- Button click
- Purchase confirmation
- Level complete
- Power unlock
- Rescue success

**Creating SFX:**

**Free Tools:**
- **Audacity** - Audio editing
- **SFXR** - Retro game sounds
- **Freesound.org** - Sound library
- **ZapSplat** - Free SFX library

**Recording:**
1. Use microphone or download from sound libraries
2. Edit in Audacity:
   - Trim silence
   - Normalize volume
   - Add effects (reverb, EQ)
3. Export as OGG Vorbis

**Specifications:**
- Format: OGG Vorbis
- Sample Rate: 44.1 kHz or 22.05 kHz (for small files)
- Mono (for non-spatial) or Stereo (for ambient)

**Export Location:** `android-game/godot-project/audio/sfx/`

---

### C. Voice Lines (Optional)

**Shaman Voice:**
- ~50 wisdom lines (one per stage + extras)
- Style: Calm, wise, mysterious
- Length: 5-15 seconds each

**Recording:**
1. Script all lines from mission data
2. Record with quality microphone
3. Edit for consistency
4. Export as OGG Vorbis

**Export Location:** `android-game/godot-project/audio/vo/`

---

## 4. Animation Creation

### A. Character Animations

**Required Animations:**

**Player:**
- Idle
- Walk
- Run
- Jump (start, loop, land)
- Attack (sword combo: 3 hits)
- Bow fire
- Knife stab
- Take damage
- Death
- Powers (Blink Step, Shadow Veil, etc.)

**Enemies:**
- Idle
- Patrol walk
- Alert
- Attack
- Take damage
- Death

**Bosses:**
- Idle
- Walk/float
- Attack patterns (3-5 per boss)
- Phase transitions
- Death

### B. Creating Animations

**In Blender:**

1. Switch to Animation workspace
2. Select armature, enter Pose Mode
3. Set keyframes:
   - Move to frame 1
   - Pose character
   - Press `I` > Location & Rotation
   - Move to next frame, repeat
4. Polish in Graph Editor
5. Export with model (glTF)

**Animation Specifications:**
- Framerate: 30 FPS (mobile optimization)
- Idle: 2-3 seconds loop
- Walk: 1 second loop
- Attacks: 0.5-1 second
- Death: 2-3 seconds

### C. Import to Godot

Animations are embedded in `.glb` files. Godot's AnimationPlayer will automatically detect them.

**Setup in Godot:**
1. Select imported scene
2. Open AnimationPlayer
3. Animations auto-loaded
4. Configure blend times
5. Set up animation tree for smooth transitions

---

## 5. Integration Workflow

### Complete Pipeline

```
1. CREATE in Blender
   ↓
2. EXPORT as .glb
   ↓
3. PLACE in android-game/godot-project/assets/
   ↓
4. OPEN Godot project
   ↓
5. Godot AUTO-IMPORTS
   ↓
6. UPDATE scenes to use new assets
   ↓
7. REPLACE placeholder meshes
   ↓
8. TEST in game
```

### Replacing Placeholder Assets

**Example: Replace Player Model**

1. Export player model from Blender as `player_character.glb`
2. Copy to `assets/models/characters/`
3. Open `scenes/player.tscn` in Godot
4. Select `Body` MeshInstance3D node
5. In Inspector, change Mesh:
   - Click current mesh
   - Load... > Select `player_character.glb`
6. Adjust collision shape if needed
7. Test in game

---

## 6. Asset Organization

### Directory Structure

```
android-game/godot-project/
├── assets/
│   ├── models/
│   │   ├── characters/
│   │   │   ├── player_boy.glb
│   │   │   ├── player_girl.glb
│   │   │   ├── enemy_soldier.glb
│   │   │   ├── enemy_wolf.glb
│   │   │   └── boss_krath.glb
│   │   ├── weapons/
│   │   │   ├── sword.glb
│   │   │   ├── knife.glb
│   │   │   └── autobow.glb
│   │   └── environment/
│   │       ├── building_small.glb
│   │       ├── crate.glb
│   │       └── barrel.glb
│   ├── textures/
│   │   ├── characters/
│   │   ├── weapons/
│   │   └── environment/
│   └── materials/
├── audio/
│   ├── music/
│   │   ├── menu_theme.ogg
│   │   ├── combat_theme.ogg
│   │   └── boss_theme.ogg
│   ├── sfx/
│   │   ├── sword_swing.ogg
│   │   ├── footstep.ogg
│   │   └── button_click.ogg
│   └── vo/
│       └── shaman_wisdom_1.ogg
└── scenes/
    ├── player.tscn
    ├── enemy.tscn
    └── boss.tscn
```

---

## 7. Free Asset Resources

### 3D Models (CC0/Free)
- **Kenney.nl** - Game assets
- **Quaternius** - Low poly models
- **Poly Pizza** - Free 3D models
- **Sketchfab** - Some free models (check license)

### Textures
- **CC0 Textures** - Free PBR textures
- **Poly Haven** - HDRIs and textures
- **FreePBR** - PBR materials

### Audio
- **Freesound.org** - Community sounds
- **ZapSplat** - Free SFX
- **Incompetech** - Royalty-free music
- **Free Music Archive** - CC music

**Important:** Always check licenses! Use CC0 or attribution-free for commercial use.

---

## 8. Performance Optimization

### Mobile Considerations

1. **Polycount**
   - Keep under 5K triangles for main characters
   - Use LOD (Level of Detail) meshes

2. **Textures**
   - Max 2048x2048 for main characters
   - Use texture atlases
   - Enable compression in Godot

3. **Audio**
   - Use OGG Vorbis (better than MP3 for Godot)
   - Lower bitrate for SFX (96-128 kbps)
   - Stream music, load SFX into memory

4. **Draw Calls**
   - Batch meshes where possible
   - Minimize unique materials

---

## 9. Quick Start Checklist

To get the game production-ready:

- [ ] Create player character models (boy/girl)
- [ ] Create 3 enemy types (soldier, wolf, elite)
- [ ] Create 1 boss model
- [ ] Create weapon models (sword, knife, bow)
- [ ] Create basic environment (buildings, props)
- [ ] Create 2 music tracks (menu, combat)
- [ ] Create 10 essential SFX (combat, UI)
- [ ] Create player animations (idle, walk, attack)
- [ ] Create enemy animations (idle, attack, death)
- [ ] Replace placeholder scenes with real assets
- [ ] Test on Android device
- [ ] Optimize for performance

---

## 10. Testing Assets in Godot

After creating assets:

1. **Visual Test**: Open game level, check appearance
2. **Animation Test**: Play animations in AnimationPlayer
3. **Collision Test**: Ensure physics work correctly
4. **Performance Test**: Check FPS on target device
5. **Audio Test**: Verify all sounds play correctly

---

**Need Help?**

- Blender Docs: https://docs.blender.org
- Godot Docs: https://docs.godotengine.org
- Asset Creation Tutorials: YouTube (search "Blender to Godot")

---

**Your game framework is complete!** The code systems are fully functional. Once you add these visual and audio assets, you'll have a production-ready game.
