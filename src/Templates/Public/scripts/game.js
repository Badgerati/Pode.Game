// game and scenes
var game = null;
var scenes = [];

// get game setup
_pg_sendAjaxRequest('/_pode_game_/setup', null, _pg_setup);
function _pg_setup(opts) {
    // add loading scene
    scenes.push(LoadScene);

    // create custom scenes
    opts.Scenes.forEach((scene) => {
        scenes.push(new Phaser.Class({
            Extends: Phaser.Scene,

            initialize: function CustomScene() {
                Phaser.Scene.call(this, { key: scene.Name, active: scene.Active });
            },

            create: function() {
                _pg_scene_create(this, scene);
            },

            update: function(time, delta) {
                _pg_scene_update(this, time, delta, scene);
            },

            objects: {
                image: {},
                sprite: {},
                music: {},
                sound: {},
                player: {},
                group: {},
                text: {},
                particle: {},
                graphic: {},
                blitter: {}
            },

            inputs: {
                keys: {},
                mouse: {
                    buttons: {},
                    motion: {
                        move: [],
                        stop: [],
                        wheel: []
                    },
                    position: {
                        x: 0,
                        y: 0
                    }
                }
            },

            handlers: {
                watchers: [],
                routines: {},
                timers: {}
            },

            state: {
                created: false,
                paused: false
            }
        }))
    });

    // load game config
    var config = {
        type: Phaser.AUTO,
        width: opts.Size.Width,
        height: opts.Size.Height,
        backgroundColour: '#000',
        physics: {
            default: 'arcade',
            arcade: {
                gravity: {
                    x: opts.Physics.Gravity.X,
                    y: opts.Physics.Gravity.Y
                },
                debug: opts.Physics.Debug
            }
        },
        audio: {
            disableWebAudio: true
        },
        scene: scenes
    };

    // create the game
    game = new Phaser.Game(config);
}

var state = {
    finished: false
};

var debug = {
    mouse_coords: null
}

var LoadScene = new Phaser.Class({
    Extends: Phaser.Scene,

    initialize: function LoadScene() {
        Phaser.Scene.call(this, { key: 'LoadScene', active: true });
    },

    preload: function() {
        var progressBar = this.add.graphics();
        var progressBox = this.add.graphics();
        progressBox.fillStyle(0x222222, 0.8);
        progressBox.fillRect(240, 270, 320, 50);

        var width = this.cameras.main.width;
        var height = this.cameras.main.height;
        var loadingText = this.make.text({
            x: width * 0.5,
            y: (height * 0.5) - 50,
            text: 'Loading...',
            style: {
                font: '20px monospace',
                fill: '#fff'
            }
        });
        loadingText.setOrigin(0.5, 0.5);

        var percentText = this.make.text({
            x: width * 0.5,
            y: (height * 0.5) - 5,
            text: '0%',
            style: {
                font: '18px monospace',
                fill: '#fff'
            }
        });
        percentText.setOrigin(0.5, 0.5);

        var assetText = this.make.text({
            x: width * 0.5,
            y: (height * 0.5) + 50,
            text: '',
            style: {
                font: '18px monospace',
                fill: '#fff'
            }
        });
        assetText.setOrigin(0.5, 0.5);

        this.load.on('progress', function(value) {
            percentText.setText(`${parseInt(value * 100)}%`);
            progressBar.clear();
            progressBar.fillStyle(0xfff, 1);
            progressBar.fillRect(250, 280, 300 * value, 30);
        });

        this.load.on('fileprogress', function(file) {
            assetText.setText(`Asset: ${file.key}`);
        });

        this.load.on('complete', function() {
            progressBar.destroy();
            progressBox.destroy();
            loadingText.destroy();
            percentText.destroy();
        });
    },

    create: function() {
        this.load.on('complete', () => {
            this.scene.switch('Default');
        });

        _pg_sendAjaxRequest('/_pode_game_/load', null, (res) => {
            _pg_convert_to_array(res.Audio).forEach(audio => {
                _pg_load_audio(this, audio.ID, audio.Path, audio.Pool);
            });
            _pg_convert_to_array(res.Images).forEach(img => {
                _pg_load_image(this, img.ID, img.Path);
            });
            _pg_convert_to_array(res.BitmapFonts).forEach(font => {
                _pg_load_bitmap_font(this, font.ID, font.Path, font.XmlPath);
            });
            _pg_convert_to_array(res.Sprites).forEach(spr => {
                _pg_load_sprite(this, spr.ID, spr.Path, { frameWidth: spr.Frames.Width, frameHeight: spr.Frames.Height });
            });
            this.load.start();
        });
    }
})
