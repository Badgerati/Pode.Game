function _pg_scene_create(scene, opts) {
    // create for a scene
    _pg_sendAjaxRequest(`/_pode_game_/scenes/${_pg_get_scene_name(scene)}/create`, null, (res) => {
        // load content
        _pg_scene_create_content(scene, res.Content);

        // custom input
        _pg_scene_create_input(scene, res.Input, opts.Input);

        // setup collision
        _pg_scene_create_collision(scene, res.Collision);

        // setup routines
        _pg_scene_create_routine(scene, res.Routine);

        // launch other scenes
        _pg_scene_create_scene(scene, res.Scene);

        // game created
        scene.state.created = true;
    });

    // debug
    if (game.config.physics.arcade.debug) {
        debug.mouse_coords = scene.add.text(20, 10, '', { fill: '#00FF00' });
    }
}

function _pg_scene_update(scene, time, delta, opts) {
    // check the current scene state
    if (state.finished || scene.state.paused || !scene.state.created) {
        return;
    }

    // detect keyboard and mouse
    _pg_scene_update_check_keyboard(scene);
    _pg_scene_update_check_mouse(scene, delta);

    // update watchers
    _pg_scene_update_watchers(scene, time, delta);

    // debug info
    _pg_scene_update_debug(scene);
}

function _pg_scene_create_content(scene, content) {
    _pg_convert_to_array(content).forEach(obj => {
        switch (obj.Type.toLowerCase()) {
            case 'player':
                scene.objects.player[obj.Metadata.Name] = _pg_add_player(scene, obj.Metadata);
                break;

            case 'image':
                scene.objects.image[obj.Metadata.Name] = _pg_add_image(scene, obj.Metadata);
                break;

            case 'sprite':
                scene.objects.sprite[obj.Metadata.Name] = _pg_add_sprite(scene, obj.Metadata);
                break;

            case 'music':
                scene.objects.music[obj.Metadata.Name] = _pg_add_music(scene, obj.Metadata);
                break;

            case 'sound':
                scene.objects.sound[obj.Metadata.Name] = _pg_add_sound(scene, obj.Metadata);
                break;

            case 'text':
                scene.objects.text[obj.Metadata.Name] = _pg_add_text(scene, obj.Metadata);
                break;

            case 'bitmaptext':
                scene.objects.bitmaptext[obj.Metadata.Name] = _pg_add_bitmap_text(scene, obj.Metadata);
                break;

            case 'group':
                scene.objects.group[obj.Metadata.Name] = _pg_add_group(scene, obj.Metadata);
                break;

            case 'particle':
                scene.objects.particle[obj.Metadata.Name] = _pg_add_particle(scene, obj.Metadata);
                break;

            case 'graphic':
                scene.objects.graphic[obj.Metadata.Name] = _pg_add_graphic(scene, obj.Metadata);
                break;

            case 'blitter':
                scene.objects.blitter[obj.Metadata.Name] = _pg_add_blitter(scene, obj.Metadata);
                break;
        }
    });
}

function _pg_scene_create_input(scene, inputs, opts) {
    if (!opts.Enabled) {
        scene.input.keyboard.enabled = false;
        return;
    }

    scene.input.mouse.disableContextMenu();

    _pg_convert_to_array(inputs).forEach(obj => {
        switch (obj.Type.toLowerCase()) {
            case 'keyboard':
                _pg_add_key(scene, obj.Metadata);
                break;

            case 'mouse':
                _pg_add_mouse(scene, obj.Metadata);
                break;
        }
    });

    //TODO: gamepad
}

function _pg_scene_create_collision(scene, collisions) {
    _pg_convert_to_array(collisions).forEach(obj => {
        switch (obj.Type.toLowerCase()) {
            case 'collide':
                _pg_add_collision(scene, obj.Metadata);
                break;

            case 'overlap':
                _pg_add_overlap(scene, obj.Metadata);
                break;
        }
    });
}

function _pg_scene_create_routine(scene, routines) {
    _pg_convert_to_array(routines).forEach(obj => {
        switch (obj.Type.toLowerCase()) {
            case 'routine':
                scene.handlers.routines[obj.Metadata.Name] = _pg_add_routine(scene, obj.Metadata);
                break;

            case 'timer':
                scene.handlers.timers[obj.Metadata.Name] = _pg_add_timer(scene, obj.Metadata);
                break;
        }
    });
}

function _pg_scene_create_scene(scene, scenes) {
    _pg_convert_to_array(scenes).forEach(obj => {
        scene.scene.launch(obj.Name);
    });
}

function _pg_scene_update_check_keyboard(scene) {
    if (!scene.input.keyboard.enabled) {
        return;
    }

    // detect key presses
    Object.keys(scene.inputs.keys).forEach((key) => {
        var keyConfig = scene.inputs.keys[key];
        var pressed = scene.input.keyboard.checkDown(keyConfig.key, keyConfig.rate);

        // is the key being pressed?
        if (pressed) {
            keyConfig.down = true;
            keyConfig.handlers.down.forEach((handler) => handler(true, keyConfig.key));
        }

        // is the key not being pressed?
        else if (keyConfig.down && keyConfig.key.isUp) {
            keyConfig.down = false;
            keyConfig.handlers.up.forEach((handler) => handler(false, keyConfig.key));
        }

        // set a player as "moving"
        if (keyConfig.movement && keyConfig.player) {
            keyConfig.player.data.values.moving[key] = pressed;
        }
    });
}

function _pg_scene_update_check_mouse(scene, delta) {
    if (!scene.input.mouse.enabled) {
        return;
    }

    // detect mouse presses
    var pointer = scene.input.activePointer;

    Object.keys(scene.inputs.mouse.buttons).forEach((btn) => {
        var btnConfig = scene.inputs.mouse.buttons[btn];
        var pressed = pointer[`${btn}ButtonDown`]();

        if (pressed) {
            btnConfig.down = true;
            btnConfig.duration += delta;

            if (btnConfig.duration >= btnConfig.rate) {
                btnConfig.duration = 0;
                btnConfig.handlers.down.forEach((handler) => handler(true, pointer));
            }
        }
        else if (btnConfig.down && pointer[`${btn}ButtonReleased`]()) {
            btnConfig.down = false;
            btnConfig.duration = btnConfig.rate + 1;
            btnConfig.handlers.up.forEach((handler) => handler(false, pointer));
        }
    });

    // detect mouse movement
    if (scene.inputs.mouse.position.x != pointer.x && scene.inputs.mouse.position.y != pointer.y) {
        scene.inputs.mouse.position = {
            x: pointer.x,
            y: pointer.y
        };

        scene.inputs.mouse.motion.move.forEach((handler) => handler(true, pointer));
    }
    else {
        scene.inputs.mouse.motion.stop.forEach((handler) => handler(false, pointer));
    }
}

function _pg_scene_update_watchers(scene, time, delta) {
    scene.handlers.watchers.forEach((watcher) => {
        watcher(scene, time, delta);
    });
}

function _pg_scene_update_debug(scene) {
    if (game.config.physics.arcade.debug) {
        var pointer = scene.input.activePointer;
        debug.mouse_coords.setText([ `x: ${pointer.x}`, `y: ${pointer.y}` ]);
    }
}