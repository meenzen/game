use macroquad::prelude::*;
#[macroquad::main("game")]
async fn main() {
    loop {
        clear_background(RED);
        next_frame().await;
    }
}
