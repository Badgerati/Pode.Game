// constants
const MIN_INT32 = (1 << 31);
const MAX_INT32 = ((2**31) - 1);

function _pg_sendAjaxRequest(url, data, successCallback, errorCallback, opts) {
    // add current query string
    if (window.location.search) {
        url = `${url}${window.location.search}`;
    }

    // set default opts
    opts = (opts ?? {});
    opts.contentType = (opts.contentType == null ? 'application/json' : opts.contentType);
    opts.processData = (opts.processData == null ? true : opts.processData);
    opts.method = (opts.method == null ? 'get' : opts.method);
    opts.async = (opts.async == null ? true : opts.async);

    // make the call
    $.ajax({
        url: url,
        async: opts.async,
        method: opts.method,
        data: data,
        dataType: 'binary',
        processData: opts.processData,
        contentType: opts.contentType,
        mimeType: opts.mimeType,
        xhrFields: {
            responseType: 'blob'
        },
        success: function(res) {
            if (successCallback) {
                res.text().then((v) => {
                    v ? successCallback(JSON.parse(v)) : successCallback();
                });
            }
        },
        error: function(err, msg, stack) {
            if (errorCallback) {
                errorCallback(err, stack);
            }
            else {
                console.log(err);
                console.log(stack);
            }
        }
    });
}

function _pg_get_scene_name(scene) {
    return scene.scene.key;
}

function _pg_add_player(scene, metadata) {
    var player = null;

    switch (metadata.Texture.Type.toLowerCase()) {
        case 'sprite':
            player = _pg_add_sprite(scene, metadata.Texture.Metadata);
            break;

        case 'image':
            player = _pg_add_image(scene, metadata.Texture.Metadata);
            break;
    }

    scene.objects[metadata.Texture.Type.toLowerCase()][metadata.Texture.Metadata.Name] = player;

    // set player data/funcs
    _pg_set_data(player, false, {
        isPlayer: true,
        stats: {
            score: metadata.Stats.Score,
            health: metadata.Stats.Health
        },
        moving: {},
        controls: {
            type: metadata.ControlType,
            isNormal: metadata.ControlType == 'normal',
            isRotate: metadata.ControlType == 'rotate',
            isMouse: metadata.Mouse,
        },
        stop: function() {
            if (player.data.values.controls.isRotate) {
                player.setAcceleration(0);
                player.setAngularVelocity(0);
            }
            else {
                player.setVelocityX(0);
                player.setVelocityY(0);
            }

            _pg_play_anim(player, 'stop');
        },
        jump: function(pressed) {
            if (pressed) {
                if (player.body.touching.down) {
                    player.setVelocityY(-metadata.Speed.Jump);
                    _pg_play_anim(player, ['jump', 'stop']);
                }
            }
        },
        crouch: function() {
            _pg_play_anim(player, 'crouch');
        },
        left: function(pressed) {
            if (pressed) {
                if (player.data.values.controls.isRotate) {
                    player.setAngularVelocity(-metadata.Speed.Move);
                }
                else {
                    player.setVelocityX(-metadata.Speed.Move);
                }
                _pg_play_anim(player, 'left', true);
            }
            else {
                if (player.data.values.controls.isRotate) {
                    player.setAngularVelocity(0);
                }
                else {
                    player.setVelocityX(0);
                }
                _pg_play_anim(player, 'stop');
            }
        },
        right: function(pressed) {
            if (pressed) {
                if (player.data.values.controls.isRotate) {
                    player.setAngularVelocity(metadata.Speed.Move);
                }
                else {
                    player.setVelocityX(metadata.Speed.Move);
                }
                _pg_play_anim(player, 'right', true);
            }
            else {
                if (player.data.values.controls.isRotate) {
                    player.setAngularVelocity(0);
                }
                else {
                    player.setVelocityX(0);
                }
                _pg_play_anim(player, 'stop');
            }
        },
        up: function(pressed) {
            if (pressed) {
                if (player.data.values.controls.isRotate) {
                    scene.physics.velocityFromRotation(player.rotation, metadata.Speed.Move, player.body.acceleration);
                }
                else {
                    player.setVelocityY(-metadata.Speed.Move);
                }
                _pg_play_anim(player, 'up', true);
            }
            else {
                if (player.data.values.controls.isRotate) {
                    player.setAcceleration(0);
                }
                else {
                    player.setVelocityY(0);
                }
                _pg_play_anim(player, 'stop');
            }
        },
        down: function(pressed) {
            if (pressed) {
                if (player.data.values.controls.isRotate) {
                    scene.physics.velocityFromRotation(player.rotation, -metadata.Speed.Move, player.body.acceleration);
                }
                else {
                    player.setVelocityY(metadata.Speed.Move);
                }
                _pg_play_anim(player, 'down', true);
            }
            else {
                if (player.data.values.controls.isRotate) {
                    player.setAcceleration(0);
                }
                else {
                    player.setVelocityY(0);
                }
                _pg_play_anim(player, 'stop');
            }
        },
        fire: function() {
            _pg_handle_actions(scene, player, metadata.FireActions);
        },
        rotate: function(pressed, x, y) {
            player.setRotation(Phaser.Math.Angle.Between(player.x, player.y, x, y));
        }
    });

    // movement - keyboard
    Object.keys(metadata.Controls).forEach((mv) => {
        if (metadata.Controls[mv]) {
            var isFire = (mv.toLowerCase() == 'fire');

            // keyboard
            if (!metadata.Mouse) {
                _pg_bind_key(scene, metadata.Controls[mv], 'down', {
                    handler: (pressed) => player.data.values[mv.toLowerCase()](pressed),
                    movement: !isFire,
                    player: player,
                    rate: (isFire ? metadata.FireRate : 0)
                });

                if (!isFire) {
                    _pg_bind_key(scene, metadata.Controls[mv], 'up', {
                        handler: (pressed) => player.data.values[mv.toLowerCase()](pressed),
                        movement: !isFire,
                        player: player,
                        rate: (isFire ? metadata.FireRate : 1)
                    });
                }
            }

            // mouse
            else {
                var evtType = metadata.Controls[mv].toLowerCase() == 'move' ? 'move' : 'down';

                _pg_bind_mouse(scene, metadata.Controls[mv], evtType, {
                    handler: (pressed, pointer) => player.data.values[mv.toLowerCase()](pressed, pointer.x, pointer.y),
                    movement: !isFire,
                    player: player,
                    rate: (isFire ? metadata.FireRate : 1)
                });

                if (!isFire && evtType == 'down') {
                    _pg_bind_mouse(scene, metadata.Controls[mv], 'up', {
                        handler: (pressed, pointer) => player.data.values[mv.toLowerCase()](pressed, pointer.x, pointer.y),
                        movement: !isFire,
                        player: player,
                        rate: (isFire ? metadata.FireRate : 1)
                    });
                }
            }
        }
    });

    return player;
}

function _pg_bind_key(scene, key, type, opts) {
    key = key.toUpperCase();

    if (!scene.inputs.keys[key]) {
        scene.inputs.keys[key] = {
            key: scene.input.keyboard.addKey(key),
            handlers: {
                down: [],
                up: []
            },
            movement: false,
            player: opts.player,
            down: false,
            rate: opts.rate ?? 1
        };
    }

    if (opts.movement) {
        scene.inputs.keys[key].movement = true;
    }

    if (opts.handler) {
        scene.inputs.keys[key].handlers[type].push(opts.handler);
    }
}

function _pg_add_key(scene, metadata) {
    var handler = () => {
        _pg_handle_result(scene, null, null, null, metadata);
    };

    _pg_bind_key(scene, metadata.Key, metadata.Type, {
        handler: handler,
        rate: metadata.Duration ?? 1
    });
}

function _pg_bind_mouse(scene, button, type, opts) {
    button = (button ?? '').toLowerCase();
    type = type.toLowerCase();

    // buttons
    switch (type) {
        case 'down':
        case 'up':
            if (!scene.inputs.mouse.buttons[button]) {
                scene.inputs.mouse.buttons[button] = {
                    handlers: {
                        down: [],
                        up: []
                    },
                    movement: false,
                    player: opts.player,
                    down: false,
                    rate: opts.rate ?? 1,
                    duration: 0
                };
            }

            if (opts.movement) {
                scene.inputs.mouse.buttons[button].movement = true;
            }
    
            if (opts.handler) {
                scene.inputs.mouse.buttons[button].handlers[type].push(opts.handler);
            }
            break;

        case 'move':
            scene.inputs.mouse.motion.move.push(opts.handler);
            break;

        case 'wheel':
            scene.inputs.mouse.motion.wheel.push(opts.handler);

            scene.input.on(type, (pointer) => {
                scene.inputs.mouse.motion.wheel.forEach((handler) => {
                    handler(pointer);
                });
            });
            break;
    }
}

function _pg_add_mouse(scene, metadata) {
    var handler = (pressed, pointer, dX, dY, dZ) => {
        var data = _pg_convert_from_pointer(pointer, dX, dY, dZ);
        _pg_handle_result(scene, pointer, null, data, metadata);
    };

    _pg_bind_mouse(scene, metadata.Button, metadata.Type, {
        handler: handler,
        rate: metadata.Duration ?? 1
    });
}

function _pg_convert_mouse_button_id(button) {
    switch (button.toLowerCase()) {
        case 'left':
            return 0;

        case 'middle':
            return 1;

        case 'right':
            return 2;

        case 'back':
            return 3;

        case 'forward':
            return 4;

        default:
            return -1;
    }
}

function _pg_convert_from_pointer(pointer, dX, dY, dZ) {
    return {
        pointer: {
            position: {
                x: pointer.x,
                y: pointer.y
            },
            down: {
                x: pointer.downX,
                y: pointer.downY
            },
            up: {
                x: pointer.upX,
                y: pointer.upY
            },
            velocity: {
                x: pointer.velocityX ?? 0,
                y: pointer.velocityY ?? 0
            },
            delta: {
                x: pointer.deltaX ?? 0,
                y: pointer.deltaY ?? 0,
                z: pointer.deltaZ ?? 0
            },
            button: pointer.button,
            distance: pointer.distance
        },
        delta: {
            x: dX ?? 0,
            y: dY ?? 0,
            z: dZ ?? 0
        }
    };
}

function _pg_add_image(scene, metadata) {
    var img = null;
    if (metadata.Static){
        img = scene.add.image(metadata.Position.X, metadata.Position.Y, metadata.ImageId);
    }
    else {
        img = scene.physics.add.image(metadata.Position.X, metadata.Position.Y, metadata.ImageId);
    }

    _pg_set_obj_properties(scene, img, metadata);
    return img;
}

function _pg_add_graphic(scene, metadata) {
    var graphic = scene.add.graphics();
    graphic.fillStyle(metadata.Colour, metadata.Alpha);

    switch (metadata.Type.toLowerCase()) {
        case 'rectangle':
            if (metadata.Size.Radius > 0) {
                graphic.fillRoundedRect(metadata.Position.X, metadata.Position.Y, metadata.Size.Width, metadata.Size.Height, metadata.Size.Radius);
            }
            else {
                graphic.fillRect(metadata.Position.X, metadata.Position.Y, metadata.Size.Width, metadata.Size.Height);
            }
            break;
    }

    _pg_set_obj_properties(scene, graphic, metadata);
    return graphic;
}

//TODO: we need to make this generic
// maybe type: CenterOut (stars), Down (rain), then Custom
function _pg_add_blitter(scene, metadata) {
    var blitter = scene.add.blitter(0, 0, metadata.ImageId);

    var x, y, z, p, bob;

    var width = _pg_get_scene_width(scene);
    var halfWidth = width * 0.5;

    var height = _pg_get_scene_height(scene);
    var halfHeight = height * 0.5;

    for (var i = 0; i < metadata.Count; i++) {
        x = Math.floor(Math.random() * width) - halfWidth;
        y = Math.floor(Math.random() * height) - halfHeight;
        z = Math.floor(Math.random() * 1700) - 100;
        p = metadata.Distance / (metadata.Distance - z);

        bob = blitter.create(halfWidth + (x * p), halfHeight + (y * p));
        bob.data.x = x;
        bob.data.y = y;
        bob.data.z = z;
    }

    scene.handlers.watchers.push((scene, time, delta) => {
        var p, bob;

        for (var i = 0; i < metadata.Count; i++) {
            bob = blitter.children.list[i];

            p = metadata.Distance / (metadata.Distance - bob.data.z);
            bob.x = halfWidth + (bob.data.x * p);
            bob.y = halfHeight + (bob.data.y * p);

            bob.data.z += metadata.Speed * (delta * 0.001);
            if (bob.data.z > halfHeight) {
                bob.data.z -= height;
            }
        }
    });
}

function _pg_add_text(scene, metadata) {
    var txt = scene.make.text({
        x: metadata.Position.X,
        y: metadata.Position.Y,
        text: metadata.Value,
        style: {
            fontSize: metadata.Style.Font.Size,
            fontFamily: metadata.Style.Font.Family,
            fill: metadata.Style.Colour
        }
    });

    if (metadata.Watch) {
        _pg_set_data(txt, false, { prepend: metadata.Value ?? '' });

        scene.handlers.watchers.push(() => {
            var target = _pg_get_object(scene, metadata.Watch.Target, txt);

            var value = target.data.values;
            metadata.Watch.Property.split('.').forEach((atom) => {
                value = value[atom];
            });

            if (metadata.Type == 'number') {
                value = parseFloat(value).toLocaleString();
            }

            txt.setText(`${txt.getData('prepend')}${value}`);
        });
    }

    return txt;
}

function _pg_add_bitmap_text(scene, metadata) {
    var txt = scene.add.bitmapText(metadata.Position.X, metadata.Position.Y, metadata.FontId, metadata.Value);
    txt.setLetterSpacing(metadata.Spacing);
    _pg_set_obj_properties(scene, txt, metadata);

    if (metadata.Watch) {
        _pg_set_data(txt, false, { prepend: metadata.Value ?? '' });

        scene.handlers.watchers.push(() => {
            var target = _pg_get_object(scene, metadata.Watch.Target, txt);

            var value = target.data.values;
            metadata.Watch.Property.split('.').forEach((atom) => {
                value = value[atom];
            });

            txt.setText(`${txt.getData('prepend')}${value}`);
        });
    }

    return txt;
}

function _pg_load_image(scene, name, path) {
    if (!Object.keys(scene.cache.game.textures.list).includes(name)) {
        scene.load.image(name, path);
    }
}

function _pg_load_bitmap_font(scene, name, path, xml) {
    scene.load.bitmapFont(name, path, xml);
}

function _pg_load_sprite(scene, name, path, opts) {
    if (!Object.keys(scene.cache.game.textures.list).includes(name)) {
        scene.load.spritesheet(name, path, opts);
    }
}

function _pg_load_audio(scene, name, path, pool) {
    if (Object.keys(scene.cache.audio.entries.entries).includes(name)) {
        return;
    }

    if (pool && pool.Size > 0) {
        for (var i = 0; i < pool.Size; i++) {
            scene.load.audio(`${name}_${i}`, path);
        }
    }
    else {
        scene.load.audio(name, path);
    }
}

function _pg_add_particle(scene, metadata) {
    var config = {
        alpha: { start: metadata.Alpha.Start, end: metadata.Alpha.End },
        scale: { start: metadata.Scale.Start, end: metadata.Scale.End },
        speedX: { min: metadata.Speed.X.Min, max: metadata.Speed.X.Max },
        speedY: { min: metadata.Speed.Y.Min, max: metadata.Speed.Y.Max },
        accelerationX: metadata.Acceleration.X,
        accelerationY: metadata.Acceleration.Y,
        angle: { min: metadata.Angle.Min, max: metadata.Angle.Max },
        rotate: { min: metadata.Rotate.Min, max: metadata.Rotate.Max },
        lifespan: { min: metadata.Lifespan.Min, max: metadata.Lifespan.Max },
        frequency: metadata.Frequency,
        quantity: metadata.Quantity,
        maxParticles: metadata.MaxParticles,
        gravityX: metadata.Gravity.X,
        gravityY: metadata.Gravity.Y
    }

    if (metadata.Colour != null) {
        config.tint = parseInt(metadata.Colour);
    }

    if (metadata.BlendMode.toLowerCase() != 'none') {
        config.blendMode = metadata.BlendMode.toUpperCase();
    }

    return _pg_add_particle_int(scene, metadata.Image, metadata.Shape, config);
}

function _pg_add_particle_int(scene, image, shape, config) {
    var particles = image
        ? scene.add.particles(image)
        : scene.add.particles(`_pg_image_particle_${shape.toLowerCase()}_`);

    _pg_set_data(particles, false, { config: config });
    return particles;
}

function _pg_show_particle(scene, metadata) {
    var position = null;

    if (metadata.Position) {
        position = { x: metadata.Position.X, y: metadata.Position.Y };
    }

    var follow = null;
    if (metadata.Follow) {
        follow = scene.objects[metadata.Follow.Type.toLowerCase()][metadata.Follow.Name];
    }

    _pg_play_particles(scene, metadata.Name, position, follow);
}

function _pg_add_sprite(scene, metadata) {
    var sprite = null;
    if (metadata.Static) {
        sprite = scene.add.sprite(metadata.Position.X, metadata.Position.Y, metadata.SpriteId);
    }
    else {
        sprite = scene.physics.add.sprite(metadata.Position.X, metadata.Position.Y, metadata.SpriteId);
    }

    _pg_set_obj_properties(scene, sprite, metadata);

    metadata.Animations.forEach(opts => {
        var anim = {
            key: opts.Type,
            frameRate: opts.Frames.Rate
        }

        if (opts.Frames.End > -1) {
            anim.repeat = -1;
            anim.frames = scene.anims.generateFrameNumbers(opts.Name, { start: opts.Frames.Start, end: opts.Frames.End });
        }
        else {
            anim.frames = [ { key: opts.Name, frame: opts.Frames.Start } ];
        }

        scene.anims.create(anim);
    })

    return sprite;
}

function _pg_add_group(scene, metadata) {
    var group = null;
    if (metadata.Static) {
        group = scene.physics.add.staticGroup();
    }
    else {
        group = scene.physics.add.group();
    }

    if (!metadata.Objects) {
        return group;
    }

    metadata.Objects.forEach(opts => {
        var obj = _pg_add_group_object(group, null, opts.Metadata.Position.X, opts.Metadata.Position.Y, opts.Metadata.Name);
        _pg_set_obj_properties(scene, obj, opts.Metadata);
    });

    return group;
}

function _pg_play_particles(scene, name, position, follow) {
    var config = scene.objects.particle[name].data.values.config

    if (position) {
        config.x = position.x;
        config.y = position.y;
    }

    var emitter = scene.objects.particle[name].createEmitter(config);

    if (follow) {
        emitter.startFollow(follow);
    }
}

function _pg_set_data(obj, allowNulls, data) {
    if (!data || obj.setData === undefined) {
        return;
    }

    Object.keys(data).forEach((key) => {
        if (data[key] != null || (data[key] == null && allowNulls)) {
            obj.setData(key, data[key]);
        }
    })
}

function _pg_set_scale(scene, obj, sender, opts) {
    if (!opts || obj.setScale === undefined) {
        return;
    }

    if (opts.X > 0 || opts.Y > 0) {
        obj.setScale((opts.X > 0 ? opts.X : 1), (opts.Y > 0 ? opts.Y : 1)).refreshBody();
    }
}

function _pg_set_bounce(scene, obj, sender, opts) {
    if (!opts || obj.setBounceX === undefined) {
        return;
    }

    obj.setBounceX(opts.X);
    obj.setBounceY(opts.Y);
}

function _pg_set_drag(scene, obj, sender, opts) {
    if (!opts || obj.setDragX === undefined) {
        return;
    }

    obj.setDamping(opts.Damping)
    obj.setDragX(opts.X);
    obj.setDragY(opts.Y);
}

function _pg_set_acceleration(scene, obj, sender, opts) {
    if (!opts || obj.setAccelerationX === undefined) {
        return;
    }

    obj.setAccelerationX(opts.X);
    obj.setAccelerationY(opts.Y);
}

function _pg_set_gravity(scene, obj, sender, opts) {
    if (!opts || obj.allowGravity === undefined) {
        return;
    }

    if (!opts.Enable) {
        obj.setGravity(0);
        obj.allowGravity = false;
    }
    else {
        obj.allowGravity = true;
        obj.setGravityX(opts.X);
        obj.setGravityY(opts.Y);
    }
}

function _pg_set_interactive(scene, obj, sender, value) {
    if (value == null || obj.setInteractive === undefined) {
        return;
    }

    obj.setInteractive(value);
}

function _pg_set_collide(scene, obj, sender, opts) {
    if (!opts || obj.setCollideWorldBounds === undefined) {
        return;
    }

    // what happens when object hits world bounds?
    switch (opts.WorldBounds) {
        case 'collide':
            obj.setCollideWorldBounds(true);
            break;

        case 'wrap':
            obj.setCollideWorldBounds(false);

            scene.handlers.watchers.push((scene) => {
                if (!obj.active) {
                    return;
                }

                scene.physics.world.wrap(obj, (obj.width + obj.height) * opts.WrapPadding);
            });
            break;

        case 'disable':
            obj.setCollideWorldBounds(false);

            scene.handlers.watchers.push(() => {
                if (!obj.active) {
                    return;
                }

                if (obj.x > 0 && obj.y > 0 && obj.x < _pg_get_scene_width(scene) && obj.y < _pg_get_scene_height(scene)) {
                    return;
                }

                _pg_disable_body(obj);
            });
            break;
    }

    // bounding volume
    switch (opts.BoundingVolume) {
        case 'circle':
            obj.setCircle((obj.width + obj.height) * 0.25);
            break;
    }

    if (opts.Immovable) {
        obj.setImmovable(opts.Immovable);
    }
}

function _pg_get_scene_width(scene) {
    return scene.sys.game.canvas.width;
}

function _pg_get_scene_height(scene) {
    return scene.sys.game.canvas.height;
}

function _pg_disable_body(body) {
    body.disableBody(true, true);
    body.emit('DISABLE', body);
}

function _pg_enable_body(body, x, y) {
    _pg_set_data(body, false, { wasDisabled: true });
    body.enableBody(true, x, y, true, true);
    body.emit('ENABLE', body);
}

function _pg_was_disabled(body) {
    return (body.data &&  body.data.values.wasDisabled == true);
}

function _pg_set_velocity(scene, obj, sender, opts) {
    if (!opts || obj.setVelocityX === undefined) {
        return;
    }

    if (opts.X != MIN_INT32) {
        obj.setVelocityX(_pg_get_number(opts.X));
    }

    if (opts.Y != MIN_INT32) {
        obj.setVelocityY(_pg_get_number(opts.Y));
    }

    if (opts.Max != MIN_INT32) {
        obj.setMaxVelocity(opts.Max);
    }

    if (opts.Angular != MIN_INT32) {
        obj.setAngularVelocity(opts.Angular);
        scene.physics.velocityFromRotation(obj.rotation, opts.Angular, obj.body.velocity);
    }
}

function _pg_get_number(opts) {
    if (typeof(opts) == 'number') {
        return opts;
    }

    if (Array.isArray(opts)) {
        return parseFloat(_pg_choose_random_item(opts));
    }

    return Phaser.Math.Between(opts.Min, opts.Max);
}

function _pg_choose_random_item(arr) {
    return arr[Phaser.Math.Between(0, arr.length - 1)];
}

function _pg_set_depth(scene, obj, sender, value) {
    if (value == null || obj.setDepth === undefined) {
        return;
    }

    obj.setDepth(value);
}

function _pg_set_angle(scene, obj, sender, opts) {
    if (opts == null || obj.setAngle === undefined) {
        return;
    }

    if (opts.Target != null) {
        var target = _pg_get_object(scene, opts.Target, sender);
        obj.setAngle(target.angle);
        return;
    }

    obj.setAngle(opts.Value);

    if (opts.Spin) {
        scene.handlers.watchers.push(() => {
            obj.setAngle(obj.angle + opts.Value);
        });
    }
}

function _pg_set_position(scene, obj, sender, opts) {
    if (opts == null || obj.setX === undefined) {
        return;
    }

    if (opts.Target != null) {
        var target = _pg_get_object(scene, opts.Target, sender);
        obj.setPosition(target.x, target.y);
        return;
    }

    if (opts.X != MIN_INT32) {
        obj.setX(_pg_get_number(opts.X));
    }
    if (opts.Y != MIN_INT32) {
        obj.setY(_pg_get_number(opts.Y));
    }
}

function _pg_set_tint(scene, obj, sender, value) {
    if (value == null || obj.setTint === undefined) {
        return;
    }

    obj.setTint(value);
}

function _pg_set_tween(scene, obj, sender, opts) {
    if (!opts) {
        return;
    }

    scene.tweens.add({
        targets: obj,
        alpha: opts.Alpha,
        yoyo: opts.Yoyo,
        hold: opts.Hold,
        loopDelay: opts.Delay,
        repeat: (opts.Loop ? -1 : 0),
        ease: `${opts.Ease}.easeInOut`,
        duration: opts.Duration
    });
}

function _pg_get_object(scene, opts, sender) {
    if (!opts) {
        return null;
    }

    if (typeof(opts) == 'string') {
        if (opts.toLowerCase() == 'sender') {
            return sender;
        }
        else {
            return null;
        }
    }

    return scene.objects[opts.Type.toLowerCase()][opts.Name];
}

function _pg_set_obj_properties(scene, obj, metadata, sender) {
    if (!sender) {
        sender = obj;
    }

    _pg_set_collide(scene, obj, sender, metadata.Collide);
    _pg_set_interactive(scene, obj, sender, metadata.Interactive);
    _pg_set_gravity(scene, obj, sender, metadata.Gravity);
    _pg_set_drag(scene, obj, sender, metadata.Drag);
    _pg_set_scale(scene, obj, sender, metadata.Scale);
    _pg_set_bounce(scene, obj, sender, metadata.Bounce);
    _pg_set_depth(scene, obj, sender, metadata.Depth);
    _pg_set_angle(scene, obj, sender, metadata.Angle);
    _pg_set_position(scene, obj, sender, metadata.Position);
    _pg_set_tint(scene, obj, sender, metadata.Tint);
    _pg_set_tween(scene, obj, sender, metadata.Tween);
    _pg_set_acceleration(scene, obj, sender, metadata.Acceleration);
    _pg_set_velocity(scene, obj, sender, metadata.Velocity);

    if (metadata.Score != null) {
        _pg_set_data(obj, false, { score: metadata.Score });
    }

    if (metadata.Events != null) {
        metadata.Events.forEach((evt) => {
            var evtType = _pg_convert_to_event(evt.Type);
            var handler = null;

            //TODO: better handle keyboard/mouse events on objects
            if (evt.EventType == 'mouse') {
                handler = (pointer, dX, dY, dZ) => {
                    if (evt.Button > -1 && evt.Button != pointer.button) {
                        return;
                    }

                    var data = _pg_convert_from_pointer(pointer, dX, dY, dZ);
                    _pg_handle_result(scene, pointer, null, data, evt);
                };
            }
            else {
                handler = (sender) => {
                    _pg_handle_result(scene, sender, null, null, evt);
                };
            }

            obj.off(evtType).on(evtType, handler);
        });
    }
}

function _pg_add_routine(scene, metadata) {
    return (sender) => {
        _pg_handle_result(scene, sender, null, null, metadata);
    };
}

function _pg_add_timer(scene, metadata) {
    var handler = () => {
        if (state.finished || scene.state.paused) {
            return;
        }

        _pg_handle_result(scene, null, null, null, metadata);
    };

    return scene.time.addEvent({
        delay: metadata.Interval,
        callback: handler,
        repeat: metadata.Count,
        loop: metadata.Loop,
        callbackScope: scene
    });
}

function _pg_convert_to_event(name) {
    switch (name.toLowerCase()) {
        case 'destroy':
            return Phaser.GameObjects.Events.DESTROY;

        case 'collide':
            return Phaser.Physics.Arcade.Events.COLLIDE;

        case 'overlap':
            return Phaser.Physics.Arcade.Events.OVERLAP;

        case 'world_bounds':
            return Phaser.Physics.Arcade.Events.WORLD_BOUNDS;

        case 'animation_update':
            return Phaser.Animations.Events.ANIMATION_UPDATE;

        default:
            return name.toUpperCase();
    }
}

function _pg_add_collision(scene, metadata) {
    scene.physics.add.collider(
        _pg_get_object(scene, metadata.Source, null),
        _pg_get_object(scene, metadata.Target, null),
        (s, t) => _pg_handle_detection(scene, metadata, s, t),
        null,
        scene
    );
}

function _pg_add_overlap(scene, metadata) {
    scene.physics.add.overlap(
        _pg_get_object(scene, metadata.Source, null),
        _pg_get_object(scene, metadata.Target, null),
        (s, t) => _pg_handle_detection(scene, metadata, s, t),
        null,
        scene
    );
}

function _pg_handle_detection(scene, metadata, source, target) {
    _pg_handle_result(scene, source, target, null, metadata);
}

function _pg_convert_to_array(arr) {
    if (arr == null) {
        return [];
    }

    if (!Array.isArray(arr)) {
        arr = [arr];
    }

    return arr;
}

function _pg_log_position(obj) {
    console.log(`${obj.x}, ${obj.y}`);
}

function _pg_add_group_object(group, sender, x, y, name) {
    var obj = group.getFirstDead();

    if (obj != null && (sender != null && obj !== sender)) {
        _pg_enable_body(obj, x, y);
    }
    else {
        obj = group.create(x, y, name);
    }

    return obj;
}

function _pg_handle_result(scene, sender, target, data, opts) {
    // sound
    if (opts.Sound) {
        _pg_play_sound(scene, opts.Sound, true);
    }

    // particles
    if (opts.Particles) {
        _pg_play_particles(scene, opts.Particles, { x: sender.x, y: sender.y });
    }

    // fixed actions
    if (opts.Actions) {
        _pg_handle_actions(scene, sender, opts.Actions);
    }

    // routines
    if (opts.Routines) {
        _pg_invoke_routine(scene, sender, opts.Routines)
    }

    // get reference
    var ref = null;
    if (opts.Reference != null) {
        ref = _pg_get_object(scene, opts.Reference, sender);
    }

    // disable
    _pg_convert_to_array(opts.Disable).forEach(type => {
        switch (type.toLowerCase()) {
            case 'target':
                _pg_disable_body(target);
                break;

            case 'source':
                _pg_disable_body(sender);
                break;

            case 'reference':
                _pg_disable_body(ref);
                break;
        }
    });

    // score
    _pg_convert_to_array(opts.Score).forEach(type => {
        switch (type.toLowerCase()) {
            case 'target':
                target.data.values.stats.score += sender.getData('score');
                break;

            case 'source':
                sender.data.values.stats.score += target.getData('score');
                break;

            case 'reference':
                ref.data.values.stats.score += target.getData('score');
                break;
        }
    });

    // custom
    if (opts.Url) {
        if (!data) {
            data = {
                source: { self: sender, data: sender && sender.data ? sender.data.values : null },
                target: { self: target, data: target && target.data ? target.data.values : null }
            };
        }

        data.reference = { self: ref, data: ref && ref.data ? ref.data.values : null }
        _pg_sendAjaxRequest(opts.Url, JSON.stringify(data), (r) => { _pg_handle_actions(scene, sender, r); }, null, { method: 'post' });
    }
}

function _pg_handle_actions(scene, sender, actions) {
    if (!actions || actions.length == 0) {
        return
    }

    _pg_convert_to_array(actions).forEach(action => {
        switch (action.Type.toLowerCase()) {
            case 'group':
                if (action.Action.toLowerCase() == 'update') {
                    var group = scene.objects.group[action.Metadata.Name];
                    action.Metadata.Objects.forEach(opts => {
                        var obj = _pg_add_group_object(group, sender, opts.Metadata.Position.X, opts.Metadata.Position.Y, opts.Metadata.Name);
                        _pg_set_obj_properties(scene, obj, opts.Metadata, sender);
                    });
                }

                if (action.Action.toLowerCase() == 'clear') {
                    var group = scene.objects.group[action.Metadata.Name];
                    group.clear(true, true);
                }
                break;

            case 'spriteanimation':
                if (action.Action.toLowerCase() == 'start') {
                    _pg_play_anim(scene.objects.sprite[action.Metadata.Name], action.Metadata.Type, action.Metadata.Force);
                }
                break;

            case 'music':
                if (action.Action.toLowerCase() == 'start') {
                    _pg_play_music(scene.objects.music[action.Metadata.Name], action.Metadata.Force);
                }
                break;

            case 'sound':
                if (action.Action.toLowerCase() == 'start') {
                    _pg_play_sound(scene, action.Metadata.Name, action.Metadata.Force);
                }
                break;

            case 'game':
                if (action.Action.toLowerCase() == 'suspend') {
                    scene.physics.pause();
                    if (action.Metadata.State.Finish) {
                        state.finished = true;
                    }
                }
                break;

            case 'scene':
                if (action.Action.toLowerCase() == 'switch') {
                    scene.scene.switch(action.Metadata.Name);
                }

                if (action.Action.toLowerCase() == 'start') {
                    scene.scene.resume(action.Metadata.Name);
                }

                if (action.Action.toLowerCase() == 'stop') {
                    scene.scene.pause(action.Metadata.Name);
                }

                if (action.Action.toLowerCase() == 'open') {
                    scene.scene.launch(action.Metadata.Name);
                }
                break;

            case 'sprite':
                if (action.Action.toLowerCase() == 'update') {
                    var sprite = scene.objects.sprite[action.Metadata.Name]

                    if (action.Metadata.Position.X != MIN_INT32) {
                        sprite.x = action.Metadata.Position.X;
                    }
                    if (action.Metadata.Position.Y != MIN_INT32) {
                        sprite.y = action.Metadata.Position.Y;
                    }

                    _pg_play_anim(sprite, action.Metadata.Animation);
                    _pg_set_obj_properties(scene, sprite, action.Metadata, sender);
                }
                break;

            case 'image':
                if (action.Action.toLowerCase() == 'update') {
                    var image = scene.objects.image[action.Metadata.Name]

                    if (action.Metadata.Position.X != MIN_INT32) {
                        image.x = action.Metadata.Position.X;
                    }
                    if (action.Metadata.Position.Y != MIN_INT32) {
                        image.y = action.Metadata.Position.Y;
                    }

                    _pg_set_obj_properties(scene, image, action.Metadata, sender);
                }
                break;

            case 'particle':
                if (action.Action.toLowerCase() == 'show') {
                    _pg_show_particle(scene, action.Metadata);
                }
                break;

            case 'routine':
                if (action.Action.toLowerCase() == 'invoke') {
                    _pg_invoke_routine(scene, sender, action.Metadata.Name);
                }
                break;

            case 'random':
                if (action.Action.toLowerCase() == 'select') {
                    _pg_handle_actions(scene, sender, _pg_choose_random_item(_pg_convert_to_array(action.Metadata.Actions)));
                }
                break;
        }
    });
}

function _pg_invoke_routine(scene, sender, name) {
    _pg_convert_to_array(name).forEach(n => scene.handlers.routines[n](sender));
}

function _pg_play_anim(obj, key, ignoreIfPlaying) {
    if (key && Array.isArray(key)) {
        key.some((k) => { return _pg_play_anim_int(obj, k, ignoreIfPlaying) });
    }
    else {
        _pg_play_anim_int(obj, key, ignoreIfPlaying);
    }
}

function _pg_play_anim_int(obj, key, ignoreIfPlaying) {
    if (key && game.anims.exists(key)) {
        obj.anims.play(key, ignoreIfPlaying);
        return true;
    }

    return false;
}

function _pg_add_music(scene, metadata) {
    return _pg_add_audio(scene, metadata.AudioId, {
        loop: metadata.Loop,
        volume: metadata.Volume,
        rate: metadata.Rate,
        play: metadata.Play
    });
}

function _pg_add_sound(scene, metadata) {
    var pool = [];
    var size = metadata.Pool.Size <= 0 ? 3 : metadata.Pool.Size;

    for (var i = 0; i < size; i++) {
        pool.push(_pg_add_audio(scene, `${metadata.AudioId}_${i}`, {
            loop: metadata.Loop,
            volume: metadata.Volume,
            rate: metadata.Rate,
            play: metadata.Play
        }));
    }

    return pool;
}

function _pg_add_audio(scene, name, opts) {
    var audio = scene.sound.add(name);

    audio.loop = opts.loop;
    audio.volume = opts.volume;
    audio.rate = opts.rate;

    if (opts.play) {
        _pg_play_audio(audio);
    }

    return audio;
}

function _pg_play_music(obj, ignoreIfPlaying) {
    _pg_play_audio(obj, ignoreIfPlaying);
}

function _pg_play_sound(scene, name, ignoreIfPlaying) {
    var pool = scene.objects.sound[name];
    var found = false;

    pool.some((s) => {
        if (!s.isPlaying) {
            found = true;
            _pg_play_audio(s, true);
        }

        return found;
    })

    if (!found && ignoreIfPlaying) {
        _pg_play_audio(pool[0], true);
    }
}

function _pg_play_audio(obj, ignoreIfPlaying) {
    if (obj.isPlaying && !ignoreIfPlaying) {
        return;
    }

    obj.play();
}

function _pg_sum_array(arr) {
    return arr && arr.length > 0 ? arr.reduce((a, b) => a + b) : 0;
}