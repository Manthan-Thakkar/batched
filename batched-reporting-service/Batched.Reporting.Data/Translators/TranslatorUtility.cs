using Batched.Reporting.Shared;

namespace Batched.Reporting.Data.Translators
{
    public static class TranslatorUtility
    {
        public static TOut Translate<TOut>(this string input)
            where TOut : struct, Enum
        {
            var str = input.ToString();

            return Enum.TryParse<TOut>(str, out TOut result)
                        && Enum.IsDefined(typeof(TOut), result)
                    ? result : default(TOut);

        }

        public static IEnumerable<TOut> Translate<TIn, TOut>(this ICollection<TIn> items, Func<TIn, TOut> translator)
        {
            if (items.IsNullOrEmpty())
                return Enumerable.Empty<TOut>();

            var _items = new List<TOut>();

            foreach (var item in items)
            {
                if (item != null)
                {
                    var _item = translator(item);
                    if (_item != null)
                        _items.Add(_item);
                }
            }
            return _items;
        }
    }
}
