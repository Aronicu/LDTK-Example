// Original: https://github.com/jakubtomsu/odin-ldtk/blob/main/example/example.odin
package game

import rl "../../raylib"

import ldtk "../../odin-ldtk"

import "core:math"

SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 720

Tile :: struct {
    src: rl.Vector2,
    dst: rl.Vector2,
    flip_x: bool,
    flip_y: bool,
}

Player_Src_Animation :: enum {
    IDLE0,
    IDLE1,
    IDLE2,
    IDLE3,
    RUN0,
    RUN1,
    RUN2,
    RUN3,
    RUN4,
    RUN5,
    IN_AIR0,
    IN_AIR1,
    IN_AIR2,
}

player: struct {
    pos: rl.Vector2,
    vel: rl.Vector2,
    last_anim_change: f64, // Might change this
    current_src_name: Player_Src_Animation,
    frame: u32,
    in_air: bool,
    running: bool,
    flip_x: bool,
}

TILE_SIZE :: 32
tile_offset: rl.Vector2
tile_columns := -1
tile_rows := -1
collision_tiles: []u8
tile_data: []Tile

player_srcs := [Player_Src_Animation]rl.Rectangle {
    .IDLE0 = {24.0 - 32.0 / 2.0, 32.0 - 32.0 / 2.0, 32.0, 32.0},
    .IDLE1 = {72.0 - 32.0 / 2.0, 32.0 - 32.0 / 2.0, 32.0, 32.0},
    .IDLE2 = {120.0 - 32.0 / 2.0, 32.0 - 32.0 / 2.0, 32.0, 32.0},
    .IDLE3 = {168.0 - 32.0 / 2.0, 32.0 - 32.0 / 2.0, 32.0, 32.0},
    .RUN0 = {24.0 - 32.0 / 2.0, 128.0 - 32.0 / 2.0, 32.0, 32.0},
    .RUN1 = {72.0 - 32.0 / 2.0, 128.0 - 32.0 / 2.0, 32.0, 32.0},
    .RUN2 = {120.0 - 32.0 / 2.0, 128.0 - 32.0 / 2.0, 32.0, 32.0},
    .RUN3 = {168.0 - 32.0 / 2.0, 128.0 - 32.0 / 2.0, 32.0, 32.0},
    .RUN4 = {220.0 - 32.0 / 2.0, 128.0 - 32.0 / 2.0, 32.0, 32.0},
    .RUN5 = {268.0 - 32.0 / 2.0, 128.0 - 32.0 / 2.0, 32.0, 32.0},
    .IN_AIR0 = {120.0 - 32.0 / 2.0, 174.0 - 32.0 / 2.0, 32.0, 32.0},
    .IN_AIR1 = {168.0 - 32.0 / 2.0, 172.0 - 32.0 / 2.0, 32.0, 32.0},
    .IN_AIR2 = {220.0 - 32.0 / 2.0, 174.0 - 32.0 / 2.0, 32.0, 32.0},
}

spritesheet: rl.Texture2D
tileset: rl.Texture2D

init :: proc() {
    rl.SetTargetFPS(144)

    spritesheet = rl.LoadTexture("assets/12 Animated Character Template.png")
    tileset = rl.LoadTexture("assets/Cavernas_by_Adam_Saltsman.png")

    if project, ok := ldtk.load_from_file("assets/foo.ldtk", context.temp_allocator).?; ok {
        for level in project.levels {
            for layer in level.layer_instances {
                switch layer.type {
                case .IntGrid:
                    tile_columns = layer.c_width
                    tile_rows = layer.c_height
                    //TILE_SIZE = 720 / tile_rows
                    collision_tiles = make([]u8, tile_columns * tile_rows)
                    tile_offset.x = f32(layer.px_total_offset_x)
                    tile_offset.y = f32(layer.px_total_offset_y)

                    for val, idx in layer.int_grid_csv {
                        collision_tiles[idx] = u8(val)
                    }


                    tile_data = make([]Tile, len(layer.auto_layer_tiles))

                    multiplier : f32 = f32(TILE_SIZE) / f32(layer.grid_size)
                    for val, idx in layer.auto_layer_tiles {
                        tile_data[idx].dst.x = f32(val.px.x) * multiplier
                        tile_data[idx].dst.y = f32(val.px.y) * multiplier
                        tile_data[idx].src.x = f32(val.src.x)
                        f := val.f
                        tile_data[idx].src.y = f32(val.src.y)
                        tile_data[idx].flip_x = bool(f & 1)
                        tile_data[idx].flip_y = bool(f & 2)
                    }
                case .Entities:
                case .Tiles:
                case .AutoLayer:
                }
            }
        }
    }

    assert(tile_columns != -1 || tile_rows != -1)

    player.last_anim_change = rl.GetTime()

    player.pos.x = 100
    player.pos.y = 300
    player.in_air = true
}

frame :: proc() {
    dt := rl.GetFrameTime()
    rl.BeginDrawing()
    rl.ClearBackground(rl.RAYWHITE)

    jump_power :: 580.0
    spd :: 50.0

    if !player.in_air {
        if rl.IsKeyDown(.W) {
            player.in_air = true
            player.vel.y -= jump_power
        }
    }

    player.running = false
    if rl.IsKeyDown(.A) {
        player.vel.x -= spd
        player.running = true
        player.flip_x = true
    }
    if rl.IsKeyDown(.D) {
        player.vel.x += spd
        player.running = true
        player.flip_x = false
    }

    epsilon : f32 = 2.0
    if player.vel.x < -epsilon || player.vel.x > epsilon {
        player.vel.x *= 0.88
    } else {
        player.vel.x = 0.0
    }

    if rl.GetTime() - player.last_anim_change > 0.08 {
        player.last_anim_change = rl.GetTime()

        if player.in_air {
            if player.vel.y > 0.0 {
                player.frame = 2
            } else if player.vel.y == 0.0 {
                player.frame = 1
            } else if player.vel.y < 0.0 {
                player.frame = 0
            }
        } else {
            if player.running {
                player.frame = (player.frame + 1) % 6
            } else {
                player.frame = (player.frame + 1) % 4
            }
        }
    }

    if player.in_air {
        player.current_src_name = Player_Src_Animation(u32(Player_Src_Animation.IN_AIR0) + (player.frame % 3))
    } else {
        if player.running {
            player.current_src_name = Player_Src_Animation(u32(Player_Src_Animation.RUN0) + player.frame)
        } else {
            player.current_src_name = Player_Src_Animation(u32(Player_Src_Animation.IDLE0) + player.frame)
        }
    }

    player.vel.y += 900 * dt

    new_pos : rl.Vector2 = player.pos + player.vel * dt

    offset: rl.Vector2
    offset.x = f32(SCREEN_WIDTH - (TILE_SIZE * tile_columns)) / 2.0

    player_coll : rl.Rectangle = {new_pos.x - 16.0, new_pos.y - 64.0, 32.0, 64.0}
    player_center_row := int(math.round((new_pos.y - 32.0) / f32(TILE_SIZE)))
    player_upper_row := int(math.round((new_pos.y - 64.0) / f32(TILE_SIZE)))
    player_column := int(math.round(new_pos.x / f32(TILE_SIZE)))

    for row := 0; row < tile_rows; row += 1 {
        for column := 0; column < tile_columns; column += 1 {
            collider := collision_tiles[row * tile_columns + column]

            if collider != 0 {
                coll : rl.Rectangle = {f32(column * TILE_SIZE) + offset.x + tile_offset.x - f32(TILE_SIZE) / 2.0, f32(row * TILE_SIZE) + offset.y + tile_offset.y - f32(TILE_SIZE) / 2.0, f32(TILE_SIZE), f32(TILE_SIZE)}
                rl.DrawRectangleRec(coll, rl.RED)
                if rl.CheckCollisionRecs(player_coll, coll) {

                    if player.in_air {
                        if row <= player_upper_row {
                            if player.vel.y < 0 {
                                player.vel.y = 0
                                new_pos.y = player.pos.y
                            }
                        }
                    }
                    
                    if row > player_center_row {
                        if player.vel.y > 0 {
                            player.in_air = false
                            player.vel.y = 0
                            new_pos.y = player.pos.y
                        }

                    } else {
                        if column > player_column || column < player_column {
                            player.vel.x = 0
                            new_pos.x = player.pos.x
                        }


                    }
                }
            }
        }
    }

    player.pos.x = new_pos.x
    player.pos.y = new_pos.y

    for val in tile_data {
        source_rect : rl.Rectangle = {val.src.x, val.src.y, 8.0, 8.0}
        if val.flip_x {
            source_rect.width *= -1.0
        }
        if val.flip_y {
            source_rect.height *= -1.0
        }
        dst_rect : rl.Rectangle = {val.dst.x + offset.x + tile_offset.x, val.dst.y + offset.y + tile_offset.y, f32(TILE_SIZE), f32(TILE_SIZE)}
        rl.DrawTexturePro(tileset, source_rect, dst_rect, {f32(TILE_SIZE/2),f32(TILE_SIZE/2)}, 0, rl.WHITE)
    }

    pos := player.pos
    source_rect := player_srcs[player.current_src_name]
    if player.flip_x {
        source_rect.width *= -1.0
    }
    dst_rect : rl.Rectangle = {pos.x, pos.y - 32.0, 64.0, 64.0}
    rl.DrawTexturePro(spritesheet, source_rect, dst_rect, {32.0,32.0}, 0, rl.WHITE)

    rl.EndDrawing()
    free_all(context.temp_allocator)
}

fini :: proc() {
    rl.UnloadTexture(spritesheet)
    rl.UnloadTexture(tileset)
}