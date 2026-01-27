package cmd

import (
	"fmt"
	"runtime/debug"
	"path/filepath"

	"github.com/spf13/cobra"
)

func getModuleName() string {
	if info, ok := debug.ReadBuildInfo(); ok {
		return filepath.Base(info.Main.Path) 
	}

	return "app"
}

func main() {
	root := &cobra.Command{
		Use: getModuleName(),
		Short: "An ECS toolchain",
		Long: "An ECS toolchain",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Printf("Hola");
		},
	}

	update := &cobra.Command{
		Use: "update",
		Short: "Installs a new version of the toolchain if there is one.",
		Long: "Installs a new version of the toolchain if there is one.",
		Args: cobra.NoArgs,
		Run: func (cmd *cobra.Command, _ []string)  {
			
		},
	}

	install := &cobra.Command{
		Use: "install <version>",
		Short: "Installs a specific version of the toolchain",
		Long: "Installs a specific version of the toolchain",
		Args: cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {

		},
	}

	new := &cobra.Command{
		Use: "new <name> [version]",
		Short: "Start a new kaitos project",
		Long: "Start a new kaitos project",
		Args: cobra.RangeArgs(1, 2),
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Printf("Created project '%s' on Godot version %s", args[0], args[1])
		},
	}

	root.AddCommand(install)
	root.AddCommand(update)
	root.AddCommand(new)
}
