SystemJS.config({
  packageConfigPaths: [
    "github:*/*.json",
    "npm:@*/*.json",
    "npm:*.json"
  ],
  globalEvaluationScope: false,
  transpiler: "plugin-typescript",

  map: {
    "bootstrap": "github:twbs/bootstrap@3.3.6",
    "coffee": "github:forresto/system-coffee@0.1.2",
    "css": "github:systemjs/plugin-css@0.1.20",
    "jquery": "github:components/jquery@2.2.0",
    "plugin-typescript": "github:frankwallis/plugin-typescript@2.5.9",
    "stats": "github:mrdoob/stats.js@r14",
    "three": "github:mrdoob/three.js@r71",
    "typeahead": "github:twitter/typeahead.js@0.10.5"
  },

  packages: {
    "troxel": {
      "format": "cjs"
    },
    "github:twitter/typeahead.js@0.10.5": {
      "map": {
        "jquery": "github:components/jquery@2.2.0"
      }
    },
    "github:twbs/bootstrap@3.3.6": {
      "map": {
        "jquery": "github:components/jquery@2.2.0"
      }
    },
    "github:frankwallis/plugin-typescript@2.5.9": {
      "map": {
        "typescript": "npm:typescript@1.7.5"
      }
    }
  }
});