package slice

import (
	"slices"
)

func Contains[T comparable](src []T, val T) bool {
	return slices.Contains(src, val)
}
